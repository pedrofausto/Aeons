class_name BattleConsequences
extends RefCounted
## Converte o resultado puro do combate em efeitos sobre o WorldState (função pura).
## Aniquilação favorece a Linha Revolucionária; Rendição por Moral favorece a Pacifista
## e permite recrutar um rendido (ou apenas libertá-lo, se não houver espaço na grade).

const DOCTRINE_SHIFT: int = 10
const SUPPORT_SURRENDER_BONUS: int = 6
const SUPPORT_DEFEAT_PENALTY: int = -5
const ALIGNMENT_BRAVE_BONUS: int = 3
const ALIGNMENT_BULLY_PENALTY: int = -5
const LEVEL_GAP_THRESHOLD: float = 3.0
const LOOT_ON_VICTORY: int = 60
const XP_ON_VICTORY: int = 45
const XP_ON_DEFEAT: int = 15

## Efeitos extras por tag de encontro (somados em caso de vitória do jogador).
const TAG_WIN_EFFECTS: Dictionary = {
	"bandit_loot": {"resources": 120},
	"moral_escort": {"alignment": 4, "popular_support": 6},
	"mythic_boss": {"resources": 200},
}
const TRAP_ANNIHILATION_PENALTY: Dictionary = {"alignment": -8, "popular_support": -5}


## `player_side` é "attacker" ou "defender"; `flags` = WorldState.active_flags (rota de honra).
## Retorna efeitos para WorldState.apply_effects mais "player_won", "xp", "recruit",
## "rewards" (Dictionary) e "drop_chance" (int).
static func compute(result: Dictionary, player_squad: SquadData, enemy_squad: SquadData, player_side: String,
		flags: Dictionary = {}) -> Dictionary:
	var effects: Dictionary = {"alignment": 0, "popular_support": 0, "doctrine": 0, "resources": 0}
	var player_won: bool = result.get("winner", "") == player_side
	var victory_type: String = result.get("victory_type", "")
	var level_gap: float = enemy_squad.average_level() - player_squad.average_level()
	var tag: String = enemy_squad.encounter_tag
	if player_won:
		effects["resources"] = LOOT_ON_VICTORY
		match victory_type:
			"annihilation":
				effects["doctrine"] = DOCTRINE_SHIFT
				if level_gap <= -LEVEL_GAP_THRESHOLD and not enemy_squad.supernatural:
					_add(effects, {"alignment": ALIGNMENT_BULLY_PENALTY, "popular_support": SUPPORT_DEFEAT_PENALTY})
				if tag == "low_level_trap":
					_add(effects, TRAP_ANNIHILATION_PENALTY)
			"morale_break":
				effects["doctrine"] = -DOCTRINE_SHIFT
				effects["popular_support"] = SUPPORT_SURRENDER_BONUS
		if level_gap >= 1.0:
			_add(effects, {"alignment": ALIGNMENT_BRAVE_BONUS, "popular_support": ALIGNMENT_BRAVE_BONUS})
		_add(effects, TAG_WIN_EFFECTS.get(tag, {}))
		_add(effects, enemy_squad.victory_effects)
	else:
		effects["popular_support"] = SUPPORT_DEFEAT_PENALTY
	if tag == "natural_wildlife":  # Treino neutro: não mexe nos eixos morais.
		for key: String in ["alignment", "popular_support", "doctrine"]:
			effects[key] = 0
	effects["player_won"] = player_won
	var era: EraConfig = WorldState.era_config
	var win_xp: int = era.xp_per_victory if era else XP_ON_VICTORY
	var loss_xp: int = era.xp_per_defeat if era else XP_ON_DEFEAT
	var gap_xp: int = (era.xp_per_level_gap if era else 0) * maxi(0, roundi(level_gap))
	effects["xp"] = (win_xp + gap_xp) if player_won else loss_xp
	effects["recruit"] = player_won and victory_type == "morale_break" and tag != "natural_wildlife"
	var reward_key: String = victory_type
	if player_won and _honor_applies(enemy_squad.honor_rule, player_squad, flags):
		reward_key = String(enemy_squad.honor_rule.get("counts_as", victory_type))
	effects["rewards"] = (enemy_squad.outcome_rewards.get(reward_key, {}) as Dictionary) if player_won else {}
	effects["drop_chance"] = enemy_squad.rare_drop_chance if player_won else 0
	return effects


static func _honor_applies(rule: Dictionary, player_squad: SquadData, flags: Dictionary) -> bool:
	return not rule.is_empty() and player_squad.average_alignment() >= float(rule.get("min_alignment", 101)) \
		and bool(flags.get(String(rule.get("flag", "")), false))


## Drop raro determinístico: a semente vem do estado (ato, dia, esquadrão).
static func rolls_drop(chance_pct: int, seed_values: Array) -> bool:
	if chance_pct <= 0:
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_values)
	return rng.randi_range(1, 100) <= chance_pct


## Aplica efeitos, XP, fadiga, recompensas, drop e recrutamento.
## Retorna {"recruited": String, "items": Array[String]} para avisos de UI.
static func apply(effects: Dictionary, player_squad: SquadData, enemy_squad: SquadData = null) -> Dictionary:
	var report: Dictionary = {"recruited": "", "items": []}
	var world_effects: Dictionary = effects.duplicate()
	for key: String in ["player_won", "xp", "recruit", "rewards", "drop_chance"]:
		world_effects.erase(key)
	WorldState.apply_effects(world_effects)
	for unit: UnitInstance in player_squad.units:
		unit.gain_experience(int(effects["xp"]))
	player_squad.add_fatigue(SquadData.FATIGUE_PER_BATTLE)
	player_squad.restore_morale()
	if enemy_squad == null:
		return report
	if bool(effects.get("player_won", false)):
		WorldState.set_flag("defeated_%s" % enemy_squad.squad_id)
	_apply_rewards(effects.get("rewards", {}), report)
	if enemy_squad.rare_drop and rolls_drop(int(effects.get("drop_chance", 0)),
			[WorldState.current_act, WorldState.day_count, enemy_squad.squad_id]):
		if WorldState.add_item(enemy_squad.rare_drop):
			report["items"].append(enemy_squad.rare_drop.display_name)
	if bool(effects.get("recruit", false)):
		report["recruited"] = recruit_surrendered(player_squad, enemy_squad)
	return report


static func _apply_rewards(rewards: Dictionary, report: Dictionary) -> void:
	if rewards.has("flag"):
		WorldState.set_flag(String(rewards["flag"]))
	if rewards.has("unlock_class"):
		WorldState.unlock_class(String(rewards["unlock_class"]))
	if rewards.has("item"):
		var item := load(String(rewards["item"])) as ItemData
		if WorldState.add_item(item):
			report["items"].append(item.display_name)


## Rendição por Moral: o 1º rendido vivo que não seja líder entra no 1º slot livre.
static func recruit_surrendered(player_squad: SquadData, enemy_squad: SquadData) -> String:
	var free_slot: int = player_squad.first_free_slot()
	if free_slot < 0:
		return ""  # Grade cheia: os rendidos são apenas libertados.
	for unit: UnitInstance in enemy_squad.units:
		if unit.is_alive() and not unit.is_leader:
			var recruit := unit.duplicate() as UnitInstance
			recruit.slot = free_slot
			recruit.reset_vitals()
			player_squad.units.append(recruit)
			enemy_squad.units.erase(unit)
			return recruit.unit_name
	return ""


static func _add(effects: Dictionary, extra: Dictionary) -> void:
	for key: String in extra:
		effects[key] = int(effects.get(key, 0)) + int(extra[key])

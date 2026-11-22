class_name BattleConsequences
extends RefCounted
## Converte o resultado puro do combate em efeitos sobre o WorldState (função pura).
## Aniquilação favorece a Linha Revolucionária; Rendição por Moral favorece a Pacifista.

const DOCTRINE_SHIFT: int = 10
const SUPPORT_SURRENDER_BONUS: int = 6
const SUPPORT_DEFEAT_PENALTY: int = -5
const ALIGNMENT_BRAVE_BONUS: int = 3
const ALIGNMENT_BULLY_PENALTY: int = -5
const LEVEL_GAP_THRESHOLD: float = 3.0
const LOOT_ON_VICTORY: int = 60
const XP_ON_VICTORY: int = 45
const XP_ON_DEFEAT: int = 15


## `player_side` é "attacker" ou "defender". Retorna efeitos para WorldState.apply_effects
## mais "player_won" (bool) e "xp" (int) para as unidades sobreviventes.
static func compute(result: Dictionary, player_squad: SquadData, enemy_squad: SquadData, player_side: String) -> Dictionary:
	var effects: Dictionary = {"alignment": 0, "popular_support": 0, "doctrine": 0, "resources": 0}
	var player_won: bool = result.get("winner", "") == player_side
	var victory_type: String = result.get("victory_type", "")
	var level_gap: float = enemy_squad.average_level() - player_squad.average_level()
	if player_won:
		effects["resources"] = LOOT_ON_VICTORY
		match victory_type:
			"annihilation":
				effects["doctrine"] = DOCTRINE_SHIFT
				if level_gap <= -LEVEL_GAP_THRESHOLD:
					effects["alignment"] = ALIGNMENT_BULLY_PENALTY
					effects["popular_support"] = SUPPORT_DEFEAT_PENALTY
			"morale_break":
				effects["doctrine"] = -DOCTRINE_SHIFT
				effects["popular_support"] = SUPPORT_SURRENDER_BONUS
		if level_gap >= 1.0:
			effects["alignment"] = int(effects["alignment"]) + ALIGNMENT_BRAVE_BONUS
			effects["popular_support"] = int(effects["popular_support"]) + ALIGNMENT_BRAVE_BONUS
	else:
		effects["popular_support"] = SUPPORT_DEFEAT_PENALTY
	effects["player_won"] = player_won
	effects["xp"] = XP_ON_VICTORY if player_won else XP_ON_DEFEAT
	return effects


## Aplica efeitos + XP + fadiga. Separado para manter `compute` testável sem autoloads.
static func apply(effects: Dictionary, player_squad: SquadData) -> void:
	var world_effects: Dictionary = effects.duplicate()
	world_effects.erase("player_won")
	world_effects.erase("xp")
	WorldState.apply_effects(world_effects)
	for unit: UnitInstance in player_squad.units:
		unit.gain_experience(int(effects["xp"]))
	player_squad.add_fatigue(SquadData.FATIGUE_PER_BATTLE)
	player_squad.restore_morale()

class_name CombatResolver
extends RefCounted
## Matemática PURA do combate 3x2 (sem dependência de nós visuais).
## Recebe dois SquadData, executa turnos por ordem de agility e retorna o battle_log.
## 100% determinístico: nenhuma chamada a RNG.

const MAX_ROUNDS: int = 3
const LEADER_FALL_MORALE_LOSS: int = 30
const SIDES: Array[String] = ["attacker", "defender"]


static func resolve(attacker: SquadData, defender: SquadData,
		attacker_order: TacticalOrder.Order = TacticalOrder.Order.NONE,
		defender_order: TacticalOrder.Order = TacticalOrder.Order.NONE) -> Array[Dictionary]:
	var squads: Dictionary = {"attacker": attacker, "defender": defender}
	var orders: Dictionary = {"attacker": attacker_order, "defender": defender_order}
	var log: Array[Dictionary] = []
	for squad: SquadData in [attacker, defender]:
		for unit: UnitInstance in squad.units:
			unit.ensure_vitals()
	var turn_order := _build_turn_order(attacker, defender)
	for round_index: int in range(1, MAX_ROUNDS + 1):
		log.append({"type": "round_start", "round": round_index})
		for actor_ref: Dictionary in turn_order:
			var side: String = actor_ref["side"]
			var actor: UnitInstance = (squads[side] as SquadData).units[actor_ref["index"]]
			if not actor.can_act():
				continue
			var foe_side: String = _other(side)
			_perform_action(actor, actor_ref, squads[side], squads[foe_side], orders[side], log)
			var ending := _check_end(attacker, defender, round_index)
			if not ending.is_empty():
				log.append(ending)
				return log
	log.append(_timeout_result(attacker, defender))
	return log


## Último evento do log (tipo "result").
static func get_result(log: Array[Dictionary]) -> Dictionary:
	return log.back() if not log.is_empty() and log.back()["type"] == "result" else {}


static func _build_turn_order(attacker: SquadData, defender: SquadData) -> Array[Dictionary]:
	var order: Array[Dictionary] = []
	for side_index: int in SIDES.size():
		var squad: SquadData = attacker if side_index == 0 else defender
		for i: int in squad.units.size():
			var unit: UnitInstance = squad.units[i]
			order.append({"side": SIDES[side_index], "index": i, "agility": unit.get_agility(),
				"tiebreak": side_index * 100 + unit.slot})
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["agility"] != b["agility"]:
			return a["agility"] > b["agility"]
		return a["tiebreak"] < b["tiebreak"])
	return order


static func _perform_action(actor: UnitInstance, actor_ref: Dictionary, own: SquadData, foes: SquadData,
		own_order: TacticalOrder.Order, log: Array[Dictionary]) -> void:
	var skill: ActionSkillData = actor.get_action()
	if skill == null:
		return
	var side: String = actor_ref["side"]
	if skill.effect == ActionSkillData.Effect.HEAL:
		var ally_index: int = _pick_lowest_hp_ally(own)
		if ally_index < 0:
			return
		var ally: UnitInstance = own.units[ally_index]
		var amount: int = actor.get_intellect() * skill.power / 100
		ally.hp = mini(ally.hp + amount, ally.get_max_hp())
		ally.morale = mini(ally.morale + skill.morale_power, ally.get_max_morale())
		log.append({"type": "action", "actor_side": side, "actor_index": actor_ref["index"],
			"skill": skill.display_name, "target_side": side, "target_index": ally_index,
			"damage": 0, "morale_damage": 0, "heal": amount, "target_hp": ally.hp, "target_morale": ally.morale})
		return
	var targets: Array[int] = _pick_targets(skill, foes, own_order)
	for target_index: int in targets:
		var target: UnitInstance = foes.units[target_index]
		var raw := _raw_damage(actor, target, skill, own.fatigue_attack_pct())
		var final := TacticalOrder.modify(own_order, raw.x, raw.y)
		var was_broken: bool = target.is_broken()
		target.hp = maxi(target.hp - final.x, 0)
		target.morale = maxi(target.morale - final.y, 0)
		log.append({"type": "action", "actor_side": side, "actor_index": actor_ref["index"],
			"skill": skill.display_name, "target_side": _other(side), "target_index": target_index,
			"damage": final.x, "morale_damage": final.y, "heal": 0,
			"target_hp": target.hp, "target_morale": target.morale})
		if not target.is_alive():
			log.append({"type": "unit_fallen", "side": _other(side), "index": target_index})
			if target.is_leader:
				_on_leader_fallen(foes, _other(side), log)
		elif target.is_broken() and not was_broken:
			log.append({"type": "unit_broken", "side": _other(side), "index": target_index})


static func _raw_damage(actor: UnitInstance, target: UnitInstance, skill: ActionSkillData, attack_pct: int) -> Vector2i:
	var damage: int = 0
	match skill.effect:
		ActionSkillData.Effect.PHYSICAL:
			var attack: int = actor.get_attack() * attack_pct / 100
			damage = maxi(1, attack * skill.power / 100 - target.get_defense() / 2)
		ActionSkillData.Effect.MAGIC:
			damage = maxi(1, actor.get_intellect() * skill.power / 100 - target.get_intellect() / 3)
		ActionSkillData.Effect.MORALE_ONLY:
			return Vector2i(0, actor.get_intellect() * skill.power / 100 + skill.morale_power)
	return Vector2i(damage, damage / 2 + skill.morale_power)


static func _pick_targets(skill: ActionSkillData, foes: SquadData, own_order: TacticalOrder.Order) -> Array[int]:
	var candidates: Array[int] = _standing_indexes(foes)
	if candidates.is_empty():
		return []
	if skill.targeting == ActionSkillData.Targeting.ALL_ENEMIES:
		return candidates
	if skill.targeting == ActionSkillData.Targeting.LEADER or TacticalOrder.targets_leader(own_order):
		var leader_index: int = foes.units.find(foes.get_leader())
		if leader_index in candidates:
			return [leader_index]
	if TacticalOrder.targets_weakest(own_order):
		return [_lowest_hp(foes, candidates)]
	var preferred_row: int = 1 if skill.targeting == ActionSkillData.Targeting.BACK_FIRST else 0
	var in_row: Array[int] = []
	for i: int in candidates:
		if foes.units[i].get_row() == preferred_row:
			in_row.append(i)
	return [_lowest_hp(foes, in_row if not in_row.is_empty() else candidates)]


## Menor HP absoluto; empate decidido pelo menor slot (determinístico).
static func _lowest_hp(squad: SquadData, pool: Array[int]) -> int:
	var best: int = pool[0]
	for i: int in pool:
		var unit: UnitInstance = squad.units[i]
		var current: UnitInstance = squad.units[best]
		if unit.hp < current.hp or (unit.hp == current.hp and unit.slot < current.slot):
			best = i
	return best


## Alvos preferenciais: vivos e ainda de pé (moral > 0); se não houver, qualquer vivo.
static func _standing_indexes(squad: SquadData) -> Array[int]:
	var standing: Array[int] = []
	var alive: Array[int] = []
	for i: int in squad.units.size():
		var unit: UnitInstance = squad.units[i]
		if unit.is_alive():
			alive.append(i)
			if not unit.is_broken():
				standing.append(i)
	return standing if not standing.is_empty() else alive


static func _pick_lowest_hp_ally(squad: SquadData) -> int:
	var best: int = -1
	var best_ratio: float = 2.0
	for i: int in squad.units.size():
		var unit: UnitInstance = squad.units[i]
		if not unit.is_alive():
			continue
		var ratio: float = float(unit.hp) / float(unit.get_max_hp())
		if ratio < best_ratio:
			best_ratio = ratio
			best = i
	return best


static func _on_leader_fallen(squad: SquadData, side: String, log: Array[Dictionary]) -> void:
	log.append({"type": "leader_fallen", "side": side})
	for i: int in squad.units.size():
		var unit: UnitInstance = squad.units[i]
		if unit.is_alive() and not unit.is_broken():
			unit.morale = maxi(unit.morale - LEADER_FALL_MORALE_LOSS, 0)
			if unit.is_broken():
				log.append({"type": "unit_broken", "side": side, "index": i})


static func _check_end(attacker: SquadData, defender: SquadData, round_index: int) -> Dictionary:
	if defender.is_annihilated():
		return _result("attacker", "annihilation", round_index)
	if attacker.is_annihilated():
		return _result("defender", "annihilation", round_index)
	if defender.is_routed():
		return _result("attacker", "morale_break", round_index)
	if attacker.is_routed():
		return _result("defender", "morale_break", round_index)
	return {}


## Fim por tempo: vence quem preservou mais HP+Moral; empate favorece o defensor.
static func _timeout_result(attacker: SquadData, defender: SquadData) -> Dictionary:
	var winner: String = "attacker" if attacker.vitality_ratio() > defender.vitality_ratio() else "defender"
	return _result(winner, "timeout", MAX_ROUNDS)


static func _result(winner: String, victory_type: String, rounds: int) -> Dictionary:
	return {"type": "result", "winner": winner, "victory_type": victory_type, "rounds": rounds}


static func _other(side: String) -> String:
	return "defender" if side == "attacker" else "attacker"

class_name CombatResolver
extends RefCounted
## Matemática PURA do combate 3x2 (sem dependência de nós visuais).
## Recebe dois SquadData, executa turnos por ordem de agility e retorna o battle_log.
## 100% determinístico: nenhuma chamada a RNG. Golpes em SkillMath; alvos em CombatTargeting.

const MAX_ROUNDS: int = 3
const LEADER_FALL_MORALE_LOSS: int = 30
const HEALTHY_THRESHOLD_PCT: int = 80
const SIDES: Array[String] = ["attacker", "defender"]


static func resolve(attacker: SquadData, defender: SquadData,
		attacker_order: TacticalOrder.Order = TacticalOrder.Order.NONE,
		defender_order: TacticalOrder.Order = TacticalOrder.Order.NONE) -> Array[Dictionary]:
	var squads: Dictionary = {"attacker": attacker, "defender": defender}
	var orders: Dictionary = {"attacker": attacker_order, "defender": defender_order}
	var state: Dictionary = SkillMath.new_state()
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
			if SkillMath.consume_confusion(actor, state):
				log.append({"type": "confused", "side": side, "index": actor_ref["index"]})
				continue
			_perform_action(actor, actor_ref, squads[side], squads[_other(side)], orders[side], state, log)
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
		own_order: TacticalOrder.Order, state: Dictionary, log: Array[Dictionary]) -> void:
	var skill: ActionSkillData = actor.get_action()
	if skill == null:
		return
	if skill.effect == ActionSkillData.Effect.HEAL:
		_heal(actor, actor_ref, skill, own, foes, state, log)
		return
	for hit_index: int in skill.hits:
		for target_index: int in CombatTargeting.pick_targets(skill, foes, own_order):
			_strike(actor, actor_ref, skill, own, foes, target_index, own_order, state, log)
	SkillMath.apply_ally_buff(skill, own, state)


static func _strike(actor: UnitInstance, actor_ref: Dictionary, skill: ActionSkillData, own: SquadData,
		foes: SquadData, target_index: int, own_order: TacticalOrder.Order, state: Dictionary,
		log: Array[Dictionary]) -> void:
	var side: String = actor_ref["side"]
	var target: UnitInstance = foes.units[target_index]
	var raw := SkillMath.hit(actor, target, skill, own.fatigue_attack_pct(), state)
	var final := TacticalOrder.modify(own_order, raw.x, raw.y)
	var was_broken: bool = target.is_broken()
	target.hp = maxi(target.hp - final.x, 0)
	target.morale = maxi(target.morale - final.y, 0)
	var drained: int = final.x * skill.lifesteal_pct / 100
	actor.hp = mini(actor.hp + drained, actor.get_max_hp())
	log.append({"type": "action", "actor_side": side, "actor_index": actor_ref["index"],
		"skill": skill.display_name, "target_side": _other(side), "target_index": target_index,
		"damage": final.x, "morale_damage": final.y, "heal": 0, "drain": drained,
		"element": skill.get_element(), "target_hp": target.hp, "target_morale": target.morale})
	if SkillMath.try_inflict(actor, target, skill, state):
		log.append({"type": "status", "side": _other(side), "index": target_index, "status": skill.inflicts_status})
	if not target.is_alive():
		log.append({"type": "unit_fallen", "side": _other(side), "index": target_index})
		if target.is_leader:
			_on_leader_fallen(foes, _other(side), log)
	elif target.is_broken() and not was_broken:
		log.append({"type": "unit_broken", "side": _other(side), "index": target_index})


static func _heal(actor: UnitInstance, actor_ref: Dictionary, skill: ActionSkillData, own: SquadData,
		foes: SquadData, state: Dictionary, log: Array[Dictionary]) -> void:
	var side: String = actor_ref["side"]
	var all_allies: bool = skill.targeting == ActionSkillData.Targeting.ALL_ALLIES
	var healthy_before: bool = CombatTargeting.all_allies_healthy(own, HEALTHY_THRESHOLD_PCT)
	var targets: Array[int] = CombatTargeting.living_indexes(own)
	if not all_allies:
		targets = [CombatTargeting.lowest_hp_ratio_ally(own)]
	for ally_index: int in targets:
		if ally_index < 0:
			continue
		var ally: UnitInstance = own.units[ally_index]
		var amount: int = actor.get_intellect() * skill.power / 100
		ally.hp = mini(ally.hp + amount, ally.get_max_hp())
		ally.morale = mini(ally.morale + skill.morale_power, ally.get_max_morale())
		log.append({"type": "action", "actor_side": side, "actor_index": actor_ref["index"],
			"skill": skill.display_name, "target_side": side, "target_index": ally_index,
			"damage": 0, "morale_damage": 0, "heal": amount, "target_hp": ally.hp, "target_morale": ally.morale})
	if skill.healthy_allies_bonus_power > 0 and healthy_before:
		var bonus := ActionSkillData.new()
		bonus.display_name = skill.display_name
		bonus.effect = ActionSkillData.Effect.MAGIC
		bonus.targeting = ActionSkillData.Targeting.ALL_ENEMIES
		bonus.power = skill.healthy_allies_bonus_power
		bonus.element = skill.bonus_element
		for target_index: int in CombatTargeting.pick_targets(bonus, foes, TacticalOrder.Order.NONE):
			_strike(actor, actor_ref, bonus, own, foes, target_index, TacticalOrder.Order.NONE, state, log)


static func _on_leader_fallen(squad: SquadData, side: String, log: Array[Dictionary]) -> void:
	log.append({"type": "leader_fallen", "side": side})
	for i: int in squad.units.size():
		var unit: UnitInstance = squad.units[i]
		if unit.is_alive() and not unit.is_broken() and not SkillMath.is_morale_immune(unit):
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

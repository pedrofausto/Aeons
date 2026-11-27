class_name CombatForecast
extends RefCounted
## Previsão pura e determinística (sem mutar estado) para Combat Forecast na UI.


static func compute(session: TurnBattleSession, action_index: int, target_index: int) -> Dictionary:
	var actor: UnitInstance = session.get_current_actor() if session != null else null
	if actor == null or session.is_finished():
		return {}
	var actions := session.get_available_actions(actor)
	if action_index < 0 or action_index >= actions.size():
		action_index = 0
	var act: Dictionary = actions[action_index]
	var foes: SquadData = session.squads[CombatResolver._other(session.player_side)]
	if String(act["kind"]) == "defend":
		return {"kind": "defend", "skill_name": "Defender", "target_name": actor.unit_name,
			"hp_damage": 0, "morale_damage": 0, "heal": 0, "hits": 1, "lethal": false, "will_break": false, "status": ""}
	var skill: ActionSkillData = act["skill"]
	var order: TacticalOrder.Order = act["order"] as TacticalOrder.Order
	if skill.effect == ActionSkillData.Effect.HEAL:
		var heal_amt: int = actor.get_intellect() * skill.power / 100
		return {"kind": "heal", "skill_name": skill.display_name,
			"target_name": "Aliados" if skill.targeting == ActionSkillData.Targeting.ALL_ALLIES else "Aliado ferido",
			"hp_damage": 0, "morale_damage": 0, "heal": heal_amt, "hits": skill.hits, "lethal": false, "will_break": false, "status": ""}
	if skill.effect == ActionSkillData.Effect.BUFF:
		return {"kind": "buff", "skill_name": skill.display_name, "target_name": "Esquadrão",
			"hp_damage": 0, "morale_damage": skill.enemy_morale_drain, "heal": 0, "hits": 1, "lethal": false, "will_break": false, "status": ""}
	var tidx: int = target_index
	if tidx < 0 or tidx >= foes.units.size() or not foes.units[tidx].is_alive():
		var auto_targets := CombatTargeting.pick_targets(skill, foes, order)
		if auto_targets.is_empty():
			return {}
		tidx = auto_targets[0]
	var target: UnitInstance = foes.units[tidx]
	var own: SquadData = session.squads[session.player_side]
	var raw := SkillMath.hit(actor, target, skill, own.fatigue_attack_pct(), session.state)
	var foe_order: int = int((session.state.get("orders", {}) as Dictionary).get(CombatResolver._other(session.player_side), TacticalOrder.Order.NONE))
	var final := TacticalOrder.mitigate(foe_order as TacticalOrder.Order, TacticalOrder.modify(order, raw.x, raw.y))
	var total_hp: int = final.x * skill.hits
	var total_mor: int = final.y * skill.hits
	var can_status: bool = not skill.inflicts_status.is_empty() and not target.class_data.has_trait("status_immune")
	if can_status and skill.inflicts_status == "POISON":
		can_status = target.get_agility() <= actor.get_agility() or target.hp * 100 < target.get_max_hp() * SkillMath.POISON_HP_GATE_PCT
	elif can_status:
		can_status = target.get_agility() < actor.get_agility()
	var lethal: bool = not actor.class_data.has_trait("non_lethal") and (target.hp - total_hp) <= 0
	var will_break: bool = not SkillMath.is_morale_immune(target) and (target.morale - total_mor) <= 0
	return {"kind": "attack", "skill_name": skill.display_name, "target_name": target.unit_name,
		"hp_damage": total_hp, "morale_damage": total_mor, "heal": 0, "hits": skill.hits,
		"lethal": lethal, "will_break": will_break, "status": skill.inflicts_status if can_status else ""}


static func format(fc: Dictionary, era: EraConfig) -> String:
	if fc.is_empty():
		return ""
	var hp_lbl: String = era.hp_label if era else "HP"
	var mor_lbl: String = era.morale_label if era else "Moral"
	match String(fc.get("kind", "")):
		"defend":
			return "Previsão: Defender (+10 %s, reduz dano)" % mor_lbl
		"heal":
			return "Previsão: %s → %s (+%d %s)" % [fc["skill_name"], fc["target_name"], int(fc["heal"]), hp_lbl]
		"buff":
			return "Previsão: %s → %s" % [fc["skill_name"], fc["target_name"]]
		_:
			var tags: Array[String] = []
			if bool(fc.get("lethal", false)):
				tags.append("Letal")
			if bool(fc.get("will_break", false)):
				tags.append("Rende")
			if not String(fc.get("status", "")).is_empty():
				tags.append(String(fc["status"]))
			var suffix: String = " [%s]" % ", ".join(tags) if not tags.is_empty() else ""
			return "Previsão: %s → %s | -%d %s, -%d %s%s" % [
				fc["skill_name"], fc["target_name"], int(fc["hp_damage"]), hp_lbl, int(fc["morale_damage"]), mor_lbl, suffix]

class_name SkillMath
extends RefCounted
## Matemática pura de um golpe: atributos, elemento, resistência, perfuração, buffs,
## imunidades e status. `state` = { "buff": {iid: %}, "status": {iid: {nome: rodadas}} }.

const EXORCISM_ELEMENTS: Array[String] = ["PURIFY", "SPIRITUAL"]


static func new_state() -> Dictionary:
	return {"buff": {}, "status": {}}


## Dano antes da resistência elemental do alvo: Vector2i(hp, moral_base).
static func base_damage(actor: UnitInstance, target: UnitInstance, skill: ActionSkillData,
		attack_pct: int, state: Dictionary) -> Vector2i:
	var buff_pct: int = 100 + int((state["buff"] as Dictionary).get(actor.get_instance_id(), 0))
	var keep_armor: int = 100 - skill.armor_pierce_pct
	match skill.effect:
		ActionSkillData.Effect.PHYSICAL:
			var attack: int = actor.get_attack() * attack_pct / 100 * buff_pct / 100
			return Vector2i(maxi(1, attack * skill.power / 100 - target.get_defense() * keep_armor / 200), 0)
		ActionSkillData.Effect.MAGIC:
			var spell: int = actor.get_intellect() * buff_pct / 100
			return Vector2i(maxi(1, spell * skill.power / 100 - target.get_intellect() * keep_armor / 300), 0)
		ActionSkillData.Effect.MORALE_ONLY:
			return Vector2i(0, actor.get_intellect() * skill.power / 100 + skill.morale_power)
	return Vector2i.ZERO


## Golpe final (antes da ordem tática): aplica resistência, exorcismo e imunidade de moral.
static func hit(actor: UnitInstance, target: UnitInstance, skill: ActionSkillData,
		attack_pct: int, state: Dictionary) -> Vector2i:
	var base := base_damage(actor, target, skill, attack_pct, state)
	var element: String = skill.get_element()
	var damage: int = base.x
	var morale: int = base.y
	var immune: bool = is_morale_immune(target)
	if skill.effect == ActionSkillData.Effect.MORALE_ONLY:
		if immune and element in EXORCISM_ELEMENTS:
			damage = morale  # Talismãs exorcizam mortos-vivos: a "moral" vira dano real.
	else:
		morale = damage / 2 + skill.morale_power
	if not immune and target.class_data.has_trait("morale_drain_immune"):
		# Ignora drenos (morale_power e golpes só de moral); ainda sente o choque do golpe.
		morale = 0 if skill.effect == ActionSkillData.Effect.MORALE_ONLY else base.x / 2
	damage = apply_resistance(damage, target, element)
	return Vector2i(damage, 0 if immune else morale)


static func apply_resistance(damage: int, target: UnitInstance, element: String) -> int:
	if damage <= 0:
		return 0
	return maxi(1, damage * target.class_data.damage_multiplier_pct(element) / 100)


static func is_morale_immune(unit: UnitInstance) -> bool:
	return unit.class_data.has_trait("morale_immune")


## Status determinístico: só pega se o alvo for mais lento que o atacante.
static func try_inflict(actor: UnitInstance, target: UnitInstance, skill: ActionSkillData, state: Dictionary) -> bool:
	if skill.inflicts_status.is_empty() or not target.is_alive():
		return false
	if target.class_data.has_trait("status_immune") or target.get_agility() >= actor.get_agility():
		return false
	var statuses: Dictionary = state["status"]
	var own: Dictionary = statuses.get(target.get_instance_id(), {})
	own[skill.inflicts_status] = 1
	statuses[target.get_instance_id()] = own
	return true


## Consome 1 rodada de CONFUSE; retorna true se a unidade perde a ação.
static func consume_confusion(unit: UnitInstance, state: Dictionary) -> bool:
	var own: Dictionary = (state["status"] as Dictionary).get(unit.get_instance_id(), {})
	if int(own.get("CONFUSE", 0)) <= 0:
		return false
	own["CONFUSE"] = int(own["CONFUSE"]) - 1
	return true


static func apply_ally_buff(skill: ActionSkillData, own: SquadData, state: Dictionary) -> void:
	if skill.ally_buff_trait.is_empty() or skill.ally_buff_attack_pct == 0:
		return
	var buffs: Dictionary = state["buff"]
	for unit: UnitInstance in own.get_living_units():
		if unit.class_data.has_trait(skill.ally_buff_trait):
			buffs[unit.get_instance_id()] = maxi(int(buffs.get(unit.get_instance_id(), 0)), skill.ally_buff_attack_pct)

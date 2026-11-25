class_name UnitInstance
extends Resource
## Estado individual (HP, Moral, XP, Alinhamento, Classe) e slot na grade 3x2.
## Slots 0..2 = fileira da frente | 3..5 = fileira de trás.

const XP_PER_LEVEL: int = 100
const HP_PER_LEVEL: int = 8
const STAT_PER_LEVEL: int = 2

@export var class_data: UnitClassData
@export var unit_name: String = ""
@export var level: int = 1
@export var experience: int = 0
@export var alignment: int = 50              # 0..100
@export var charisma: int = 50               # 0..100
@export_range(0, 5) var slot: int = 0        # 0..2 frente | 3..5 trás
@export var is_leader: bool = false
@export var hp: int = -1                     # -1 = cheio ao iniciar
@export var morale: int = -1

@export_group("Equipamentos")
@export var equipped_weapon: ItemData
@export var equipped_armor: ItemData


static func create(cls: UnitClassData, p_name: String, p_level: int, p_slot: int,
		p_leader: bool = false, p_alignment: int = 50, p_charisma: int = 50) -> UnitInstance:
	var unit := UnitInstance.new()
	unit.class_data = cls
	unit.unit_name = p_name
	unit.level = p_level
	unit.slot = p_slot
	unit.is_leader = p_leader
	unit.alignment = p_alignment
	unit.charisma = p_charisma
	unit.reset_vitals()
	return unit


func ensure_vitals() -> void:
	if hp < 0:
		hp = get_max_hp()
	if morale < 0:
		morale = get_max_morale()


func reset_vitals() -> void:
	hp = get_max_hp()
	morale = get_max_morale()


func _equip_bonus(stat_prop: StringName) -> int:
	var total: int = 0
	for item: ItemData in get_equipped_items():
		total += int(item.get(stat_prop))
	return total


func get_equipped_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	if equipped_weapon != null:
		items.append(equipped_weapon)
	if equipped_armor != null:
		items.append(equipped_armor)
	return items


func get_max_hp() -> int:
	return class_data.max_hp + (level - 1) * HP_PER_LEVEL + _equip_bonus(&"bonus_hp")


func get_max_morale() -> int:
	return class_data.max_morale


func get_attack() -> int:
	return class_data.attack + (level - 1) * STAT_PER_LEVEL + _equip_bonus(&"bonus_attack")


func get_defense() -> int:
	return class_data.defense + (level - 1) * STAT_PER_LEVEL + _equip_bonus(&"bonus_defense")


func get_intellect() -> int:
	return class_data.intellect + (level - 1) * STAT_PER_LEVEL + _equip_bonus(&"bonus_intellect")


func get_agility() -> int:
	return class_data.agility + (level - 1) * STAT_PER_LEVEL + _equip_bonus(&"bonus_agility")


func get_charisma() -> int:
	return clampi(charisma + _equip_bonus(&"bonus_charisma"), 0, 100)


func get_row() -> int:
	return 0 if slot < 3 else 1


func get_column() -> int:
	return slot % 3


func is_alive() -> bool:
	return hp > 0


func is_broken() -> bool:
	return morale <= 0


func can_act() -> bool:
	return is_alive() and not is_broken()


func get_action() -> ActionSkillData:
	return class_data.front_action if get_row() == 0 else class_data.back_action


## Retorna true se subiu de nível.
func gain_experience(amount: int) -> bool:
	if not is_alive():
		return false
	experience += amount
	var leveled: bool = false
	while experience >= XP_PER_LEVEL:
		experience -= XP_PER_LEVEL
		level += 1
		hp = mini(hp + HP_PER_LEVEL, get_max_hp())
		leveled = true
	return leveled


func change_alignment(delta: int) -> void:
	alignment = clampi(alignment + delta, 0, 100)


func equip_item(item: ItemData) -> bool:
	if item == null or not item.can_equip_by(class_data):
		return false
	if item.slot == ItemData.SlotType.WEAPON_OR_TOOL:
		equipped_weapon = item
	elif item.slot == ItemData.SlotType.ARMOR_OR_RELIC:
		equipped_armor = item
	else:
		return false
	if item.alignment_shift_on_equip != 0:
		change_alignment(item.alignment_shift_on_equip)
	if hp > 0:
		hp = mini(hp + maxi(0, item.bonus_hp), get_max_hp())
	return true


func unequip_slot(slot_type: ItemData.SlotType) -> ItemData:
	var previous: ItemData = null
	if slot_type == ItemData.SlotType.WEAPON_OR_TOOL:
		previous = equipped_weapon
		equipped_weapon = null
	elif slot_type == ItemData.SlotType.ARMOR_OR_RELIC:
		previous = equipped_armor
		equipped_armor = null
	if hp > 0:
		hp = mini(hp, get_max_hp())
	return previous


func meets_requirements(target: UnitClassData) -> bool:
	return level >= target.min_level \
		and alignment >= target.min_alignment \
		and alignment <= target.max_alignment \
		and get_charisma() >= target.min_charisma


func get_eligible_promotions() -> Array[UnitClassData]:
	var result: Array[UnitClassData] = []
	for target: UnitClassData in class_data.get_promotion_targets():
		if meets_requirements(target):
			result.append(target)
	return result


func promote(target: UnitClassData) -> bool:
	if target not in class_data.get_promotion_targets() or not meets_requirements(target):
		return false
	var hp_ratio: float = float(hp) / float(get_max_hp())
	class_data = target
	hp = maxi(1, roundi(hp_ratio * float(get_max_hp()))) if hp > 0 else 0
	morale = get_max_morale()
	return true

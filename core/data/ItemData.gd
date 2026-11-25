class_name ItemData
extends Resource
## Item de campanha ou equipamento (inventário do ato atual em WorldState.inventory).

enum SlotType { NONE, WEAPON_OR_TOOL, ARMOR_OR_RELIC }
enum Category { CAMPAIGN, WEAPON, ARMOR, RELIC_PROMOTION, SUPPORT_GEAR, ARTIFACT }

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var unique: bool = false
@export var march_speed_bonus_pct: int = 0       # Soma à marcha dos esquadrões do jogador
@export var reveals_night_encounters: bool = false
@export var promotion_seal: bool = false         # Selo para promoções de classes místicas

@export var slot: SlotType = SlotType.NONE
@export var category: Category = Category.CAMPAIGN
@export var icon_texture: Texture2D

@export_group("Bônus de Equipamento")
@export var bonus_hp: int = 0
@export var bonus_attack: int = 0
@export var bonus_defense: int = 0
@export var bonus_intellect: int = 0
@export var bonus_agility: int = 0
@export var bonus_charisma: int = 0
@export var alignment_shift_on_equip: int = 0

@export_group("Restrições e Promoção")
@export var allowed_archetypes: Array[UnitClassData.Archetype] = []  # Vazio = qualquer arquétipo
@export var unlocks_class_id: String = ""


func is_equippable() -> bool:
	return slot != SlotType.NONE


func can_equip_by(cls: UnitClassData) -> bool:
	if not is_equippable() or cls == null:
		return false
	return allowed_archetypes.is_empty() or cls.archetype in allowed_archetypes


func stat_summary() -> String:
	var parts: PackedStringArray = []
	var pairs: Array[Array] = [
		[bonus_hp, "HP"], [bonus_attack, "ATQ"], [bonus_defense, "DEF"],
		[bonus_intellect, "INT"], [bonus_agility, "AGI"], [bonus_charisma, "CHA"],
	]
	for pair: Array in pairs:
		var val: int = int(pair[0])
		if val != 0:
			parts.append("%+d %s" % [val, String(pair[1])])
	return "  ".join(parts)

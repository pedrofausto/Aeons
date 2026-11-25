class_name CharacterCreationTest
extends Control
## Cena de visualização e teste de criação de personagem, equipamentos e grade 3x2.

var _classes: Array[UnitClassData] = []
var _items: Array[ItemData] = []
var _unit: UnitInstance
var _row: int = 0

@onready var _class_select: OptionButton = %ClassSelect
@onready var _row_button: Button = %RowButton
@onready var _stats_label: Label = %StatsLabel
@onready var _actions_label: Label = %ActionsLabel
@onready var _equipped_box: VBoxContainer = %EquippedBox
@onready var _catalog_box: VBoxContainer = %CatalogBox
@onready var _sprite_preview: TextureRect = %SpritePreview
@onready var _portrait_preview: TextureRect = %PortraitPreview


func _ready() -> void:
	var era: EraConfig = WorldState.era_config
	if era == null:
		return
	theme = era.ui_theme
	_classes = era.unit_classes
	for item: ItemData in era.item_catalog:
		if item.is_equippable():
			_items.append(item)
	for cls: UnitClassData in _classes:
		_class_select.add_item("%s (%s)" % [cls.display_name, UnitClassData.Archetype.keys()[cls.archetype]])
	_class_select.item_selected.connect(select_class_index)
	_row_button.pressed.connect(func() -> void: set_row(1 if _row == 0 else 0))
	if not _classes.is_empty():
		select_class_index(0)
	if OS.is_debug_build():
		print("TEST_PASS|character_creation_boot|classes=%d|items=%d" % [_classes.size(), _items.size()])


func select_class_index(idx: int) -> void:
	if idx < 0 or idx >= _classes.size():
		return
	_class_select.select(idx)
	var cls: UnitClassData = _classes[idx]
	_unit = UnitInstance.create(cls, cls.display_name, 1, 0 if _row == 0 else 3, true)
	_refresh()


func set_row(row: int) -> void:
	_row = clampi(row, 0, 1)
	if _unit != null:
		_unit.slot = 0 if _row == 0 else 3
	_refresh()


func equip_preview_item(item: ItemData) -> bool:
	if _unit == null or item == null:
		return false
	var ok: bool = _unit.equip_item(item)
	_refresh()
	return ok


func get_preview_unit() -> UnitInstance:
	return _unit


func _refresh() -> void:
	if _unit == null:
		return
	_row_button.text = "Fileira: Frente (0..2)" if _row == 0 else "Fileira: Trás (3..5)"
	var cls: UnitClassData = _unit.class_data
	_sprite_preview.texture = cls.sprite_texture
	_portrait_preview.texture = cls.portrait_texture
	_stats_label.text = "%s\nHP: %d  ATQ: %d  DEF: %d\nINT: %d  AGI: %d  CHA: %d\nAlinhamento: %d  Tamanho 3x2: %d" % [
		cls.display_name, _unit.get_max_hp(), _unit.get_attack(), _unit.get_defense(),
		_unit.get_intellect(), _unit.get_agility(), _unit.get_charisma(),
		_unit.alignment, cls.grid_slots]
	var f_name: String = cls.front_action.display_name if cls.front_action else "-"
	var f_meta: String = "(%d%% x%d)" % [cls.front_action.power, cls.front_action.hits] if cls.front_action else ""
	var b_name: String = cls.back_action.display_name if cls.back_action else "-"
	var b_meta: String = "(%d%% x%d)" % [cls.back_action.power, cls.back_action.hits] if cls.back_action else ""
	_actions_label.text = "%sFrente: %s %s\n%sTrás: %s %s" % [
		"▶ " if _row == 0 else "  ", f_name, f_meta,
		"▶ " if _row == 1 else "  ", b_name, b_meta]
	_rebuild_equipped()
	_rebuild_catalog()


func _rebuild_equipped() -> void:
	for child: Node in _equipped_box.get_children():
		_equipped_box.remove_child(child)
		child.queue_free()
	for slot_type: int in [ItemData.SlotType.WEAPON_OR_TOOL, ItemData.SlotType.ARMOR_OR_RELIC]:
		var eq: ItemData = _unit.equipped_weapon if slot_type == ItemData.SlotType.WEAPON_OR_TOOL else _unit.equipped_armor
		var row := HBoxContainer.new()
		if eq != null and eq.icon_texture != null:
			var icon := TextureRect.new()
			icon.texture = eq.icon_texture
			icon.custom_minimum_size = Vector2(18, 18)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(icon)
		var lbl := Label.new()
		lbl.text = eq.display_name if eq != null else ("(Arma/Ferramenta vazia)" if slot_type == 1 else "(Armadura/Relíquia vazia)")
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		if eq != null:
			var btn := Button.new()
			btn.text = "Remover"
			btn.pressed.connect(func() -> void:
				_unit.unequip_slot(slot_type as ItemData.SlotType)
				_refresh())
			row.add_child(btn)
		_equipped_box.add_child(row)


func _rebuild_catalog() -> void:
	for child: Node in _catalog_box.get_children():
		_catalog_box.remove_child(child)
		child.queue_free()
	for item: ItemData in _items:
		var btn := Button.new()
		btn.icon = item.icon_texture
		btn.expand_icon = true
		btn.text = "%s (%s)" % [item.display_name, item.stat_summary()]
		btn.disabled = not item.can_equip_by(_unit.class_data)
		btn.pressed.connect(func() -> void: equip_preview_item(item))
		_catalog_box.add_child(btn)

class_name EquipmentPanel
extends PanelContainer
## Painel de equipamentos dos esquadrões do jogador (armas/ferramentas e armaduras/relíquias).

signal equipment_changed(unit: UnitInstance)

var _list: VBoxContainer


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(460, 240)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(448, 228)
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)


func open() -> void:
	rebuild()
	visible = true


func rebuild() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var era: EraConfig = WorldState.era_config
	var title := Label.new()
	title.text = era.equipment_title if era else "Equipamentos"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(title)
	for squad: SquadData in WorldState.player_squads:
		for unit: UnitInstance in squad.units:
			_add_unit_block(unit)
	var close := Button.new()
	close.text = era.close_label if era else "Fechar"
	close.pressed.connect(func() -> void: visible = false)
	_list.add_child(close)
	reset_size()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _add_unit_block(unit: UnitInstance) -> void:
	var header := Label.new()
	header.text = "%s (%s Nv%d) — HP %d | ATQ %d | DEF %d | INT %d | AGI %d | CHA %d" % [
		unit.unit_name, unit.class_data.display_name, unit.level,
		unit.get_max_hp(), unit.get_attack(), unit.get_defense(),
		unit.get_intellect(), unit.get_agility(), unit.get_charisma()]
	_list.add_child(header)
	for slot_type: int in [ItemData.SlotType.WEAPON_OR_TOOL, ItemData.SlotType.ARMOR_OR_RELIC]:
		var eq: ItemData = unit.equipped_weapon if slot_type == ItemData.SlotType.WEAPON_OR_TOOL else unit.equipped_armor
		if eq != null:
			_list.add_child(_equipped_row(unit, eq, slot_type as ItemData.SlotType))
	for item: ItemData in WorldState.inventory:
		if item.can_equip_by(unit.class_data):
			_list.add_child(_equip_button(unit, item))


func _equipped_row(unit: UnitInstance, item: ItemData, slot_type: ItemData.SlotType) -> HBoxContainer:
	var row := HBoxContainer.new()
	if item.icon_texture != null:
		var icon := TextureRect.new()
		icon.texture = item.icon_texture
		icon.custom_minimum_size = Vector2(16, 16)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	var lbl := Label.new()
	lbl.text = "%s (%s)" % [item.display_name, item.stat_summary()]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var btn := Button.new()
	btn.text = "Remover"
	btn.pressed.connect(_unequip.bind(unit, slot_type))
	row.add_child(btn)
	return row


func _equip_button(unit: UnitInstance, item: ItemData) -> Button:
	var btn := Button.new()
	btn.icon = item.icon_texture
	btn.expand_icon = true
	btn.text = "Equipar %s (%s)" % [item.display_name, item.stat_summary()]
	btn.pressed.connect(_equip.bind(unit, item))
	return btn


func _equip(unit: UnitInstance, item: ItemData) -> void:
	if not item.can_equip_by(unit.class_data):
		return
	var prev: ItemData = unit.unequip_slot(item.slot)
	if prev != null:
		WorldState.add_item(prev)
	WorldState.consume_item(item.item_id)
	unit.equip_item(item)
	equipment_changed.emit(unit)
	WorldState._notify()
	rebuild()


func _unequip(unit: UnitInstance, slot_type: ItemData.SlotType) -> void:
	var prev: ItemData = unit.unequip_slot(slot_type)
	if prev != null:
		WorldState.add_item(prev)
		equipment_changed.emit(unit)
		WorldState._notify()
	rebuild()

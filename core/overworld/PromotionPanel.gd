class_name PromotionPanel
extends PanelContainer
## Lista as promoções cumpridas em atributos. Bloqueia o botão quando falta o item exigido,
## mostra o requisito e consome 1 unidade do item ao confirmar (PromotionRules).

signal promoted(unit: UnitInstance, target: UnitClassData)

var _list: VBoxContainer


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(360, 0)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	add_child(_list)


func open() -> void:
	rebuild()
	visible = true


func rebuild() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var era: EraConfig = WorldState.era_config
	var title := Label.new()
	title.text = era.promotion_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(title)
	for squad: SquadData in WorldState.player_squads:
		for unit: UnitInstance in squad.units:
			for option: Dictionary in PromotionRules.options_for(unit):
				_list.add_child(_option_button(unit, option, era))
	var close := Button.new()
	close.text = era.close_label
	close.pressed.connect(func() -> void: visible = false)
	_list.add_child(close)
	reset_size()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _option_button(unit: UnitInstance, option: Dictionary, era: EraConfig) -> Button:
	var target: UnitClassData = option["target"]
	var button := Button.new()
	button.name = "Promote_%s_%s" % [unit.unit_name.validate_node_name(), target.class_id]
	button.text = "%s (%s) → %s" % [unit.unit_name, unit.class_data.display_name, target.display_name]
	var item_id: String = option["item_id"]
	if not item_id.is_empty():
		var template: String = era.promotion_consumes if option["has_item"] else era.promotion_requires
		button.text += "\n" + template % [era.get_item_name(item_id), int(option["owned"])]
	if not option["doctrine_ok"]:
		button.text += "\n" + era.promotion_doctrine % [era.doctrine_label, target.min_doctrine, target.max_doctrine]
	if option["forbidden"]:
		button.text += "\n" + era.promotion_forbidden
	button.disabled = not bool(option["available"])
	button.pressed.connect(_confirm.bind(unit, target))
	return button


func _confirm(unit: UnitInstance, target: UnitClassData) -> void:
	if PromotionRules.promote(unit, target):
		promoted.emit(unit, target)
	rebuild()

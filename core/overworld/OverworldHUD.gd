class_name OverworldHUD
extends Control
## HUD do mapa: indicadores do WorldState com o vocabulário do EraConfig ativo.

signal pause_pressed
signal debug_transition_pressed
signal promote_pressed

@onready var _stats: Label = %Stats
@onready var _pause_label: Label = %PauseLabel
@onready var _banner: Label = %Banner
@onready var _pause_button: Button = %PauseButton
@onready var _debug_button: Button = %DebugTransitionButton
@onready var _promote_button: Button = %PromoteButton
@onready var promotion_panel: PromotionPanel = %PromotionPanel
@onready var _equip_button: Button = %EquipButton
@onready var equipment_panel: EquipmentPanel = %EquipmentPanel
@onready var _enter_button: Button = %EnterButton


func _ready() -> void:
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_debug_button.pressed.connect(func() -> void: debug_transition_pressed.emit())
	_promote_button.pressed.connect(_on_promote)
	_equip_button.pressed.connect(_on_equip)
	_enter_button.pressed.connect(_on_enter_location)
	_debug_button.visible = OS.is_debug_build()
	EventBus.world_state_changed.connect(refresh)
	promotion_panel.promoted.connect(func(_u: UnitInstance, _c: UnitClassData) -> void: refresh())
	equipment_panel.equipment_changed.connect(func(_u: UnitInstance) -> void: refresh())
	EventBus.pause_toggled.connect(func(_p: bool) -> void: refresh())
	refresh()


func refresh() -> void:
	var era: EraConfig = WorldState.era_config
	if era == null:
		return
	theme = era.ui_theme
	var map := get_tree().current_scene as OverworldMap
	var net_str: String = " (%+d/d)" % map.get_daily_net_income() if map != null else ""
	_stats.text = "%s — %s %d %s   |   %s: %d%s   |   %s: %d   |   %s: %d   |   %s: %+d" % [
		era.era_title, era.day_label, WorldState.day_count, era.time_of_day_labels.get(WorldState.time_of_day, ""),
		era.resource_label, WorldState.resources, net_str,
		era.alignment_label, WorldState.alignment,
		era.support_label, WorldState.popular_support,
		era.doctrine_label, WorldState.doctrine]
	_pause_label.visible = WorldState.is_paused
	_debug_button.visible = OS.is_debug_build() and not era.next_era_config.is_empty()
	_pause_button.text = "▶" if WorldState.is_paused else "❚❚"
	_promote_button.visible = WorldState.player_squads.any(
		func(squad: SquadData) -> bool: return squad.has_eligible_promotion())
	_equip_button.text = era.equipment_button_label
	var has_eq_inv: bool = WorldState.inventory.any(func(i: ItemData) -> bool: return i.is_equippable())
	var has_eq_unit: bool = WorldState.player_squads.any(func(s: SquadData) -> bool:
		return s.units.any(func(u: UnitInstance) -> bool: return not u.get_equipped_items().is_empty()))
	_equip_button.visible = has_eq_inv or has_eq_unit
	var tok: SquadToken = map.selected_token if map != null else null
	_enter_button.visible = tok != null and not tok.is_moving() and WorldState.get_node_faction(tok.squad.current_node_id) == "player"


## `seconds` > 0: o aviso some sozinho (só se não tiver sido trocado por outro).
func _on_promote() -> void:
	promote_pressed.emit()
	promotion_panel.theme = theme
	promotion_panel.open()


func _on_equip() -> void:
	equipment_panel.theme = theme
	equipment_panel.open()


func _on_enter_location() -> void:
	var map := get_tree().current_scene as OverworldMap
	if map != null and map.selected_token != null:
		map._director.open_location(map.selected_token.squad.current_node_id)


func show_banner(text: String, seconds: float = 0.0) -> void:
	_banner.text = text
	_banner.visible = not text.is_empty()
	if seconds > 0.0 and is_inside_tree():
		await get_tree().create_timer(seconds).timeout
		if _banner.text == text:
			_banner.visible = false

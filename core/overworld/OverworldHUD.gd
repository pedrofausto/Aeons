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


func _ready() -> void:
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_debug_button.pressed.connect(func() -> void: debug_transition_pressed.emit())
	_promote_button.pressed.connect(func() -> void: promote_pressed.emit())
	_debug_button.visible = OS.is_debug_build()
	EventBus.world_state_changed.connect(refresh)
	EventBus.pause_toggled.connect(func(_p: bool) -> void: refresh())
	refresh()


func refresh() -> void:
	var era: EraConfig = WorldState.era_config
	if era == null:
		return
	theme = era.ui_theme
	_stats.text = "%s — %s %d   |   %s: %d   |   %s: %d   |   %s: %d   |   %s: %+d" % [
		era.era_title, era.day_label, WorldState.day_count,
		era.resource_label, WorldState.resources,
		era.alignment_label, WorldState.alignment,
		era.support_label, WorldState.popular_support,
		era.doctrine_label, WorldState.doctrine]
	_pause_label.visible = WorldState.is_paused
	_pause_button.text = "▶" if WorldState.is_paused else "❚❚"
	_promote_button.visible = WorldState.player_squads.any(
		func(squad: SquadData) -> bool: return squad.has_eligible_promotion())


func show_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = not text.is_empty()

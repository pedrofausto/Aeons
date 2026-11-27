class_name TitleScreen
extends Control
## Tela inicial: Tempestade com 7 silhuetas, Continuar, Novo Jogo, Carregar e Opções.

@onready var _storm: StormBackdrop = %StormBackdrop
@onready var _title: Label = %TitleLabel
@onready var _continue_btn: Button = %ContinueButton
@onready var _load_btn: Button = %LoadButton
@onready var _quit_btn: Button = %QuitButton
@onready var _menu_box: VBoxContainer = %MenuBox
@onready var _options_panel: OptionsPanel = %OptionsPanel
@onready var _save_load_modal: SaveLoadModal = %SaveLoadModal


func _ready() -> void:
	_storm.flash_changed.connect(_on_storm_flash)
	_continue_btn.pressed.connect(_on_continue_pressed)
	%NewGameButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://core/ui/ProtagonistSelect.tscn"))
	_load_btn.pressed.connect(func() -> void:
		_menu_box.visible = false
		_save_load_modal.open("load"))
	%OptionsButton.pressed.connect(func() -> void:
		_menu_box.visible = false
		_options_panel.open())
	_quit_btn.visible = not OS.has_feature("web")
	_quit_btn.pressed.connect(func() -> void: get_tree().quit())

	_options_panel.closed.connect(_on_modal_closed)
	_save_load_modal.closed.connect(_on_modal_closed)
	_save_load_modal.slot_loaded.connect(func(_slot: int) -> void:
		get_tree().change_scene_to_file("res://core/overworld/OverworldMap.tscn"))
	_refresh_save_buttons()
	if OS.is_debug_build():
		print("TEST_PASS|title_screen_boot")


func _refresh_save_buttons() -> void:
	var has_save := SaveSystem.has_any_save()
	_continue_btn.visible = has_save
	_load_btn.disabled = not has_save


func _on_continue_pressed() -> void:
	var latest := SaveSystem.get_latest_slot()
	if latest >= 0 and SaveSystem.load_slot(latest):
		get_tree().change_scene_to_file("res://core/overworld/OverworldMap.tscn")


func _on_modal_closed() -> void:
	_menu_box.visible = true
	_refresh_save_buttons()


func _on_storm_flash(intensity: float) -> void:
	_title.modulate = Color(0.86, 0.84, 0.78).lerp(Color(1.0, 0.98, 0.94), intensity)

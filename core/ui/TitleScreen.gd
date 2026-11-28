class_name TitleScreen
extends Control
## Tela inicial com máquina de estados (BOOT_SILENCE -> INTRO_REVEAL -> IDLE_PRESS_START
## -> ATTRACT_MODE -> MENU_ACTIVE -> TRANSITION_OUT), tempestade e menu em cascata.

enum State { BOOT_SILENCE, INTRO_REVEAL, IDLE_PRESS_START, ATTRACT_MODE, MENU_ACTIVE, TRANSITION_OUT }

const IDLE_TO_ATTRACT_SEC := 30.0
const TITLE_BASE_Y := 34.0
const EPIGRAPHIES: Array[String] = [
	"\"O Céu não responde a decretos; observa quem mantém a mão firme na tempestade.\"",
	"\"Muralhas caem pela lâmina ou pela fome; mas um reino só cai quando perde a própria alma.\"",
	"\"Mesmo sob nuvens fechadas, as estrelas fixas permanecem onde sempre estiveram.\"",
]

var _state: State = State.BOOT_SILENCE
var _idle_timer: float = 0.0
var _epigraph_idx: int = 0
var _phase_tween: Tween
var _logo_float_tween: Tween
var _press_pulse_tween: Tween
var _attract_tween: Tween

@onready var _storm: StormBackdrop = %StormBackdrop
@onready var _curtain: ColorRect = %BlackCurtain
@onready var _title: Label = %TitleLabel
@onready var _subtitle: Label = %SubtitleLabel
@onready var _press_label: Label = %PressStartLabel
@onready var _attract_overlay: Control = %AttractOverlay
@onready var _attract_label: Label = %AttractLabel
@onready var _menu_box: VBoxContainer = %MenuBox
@onready var _continue_btn: Button = %ContinueButton
@onready var _load_btn: Button = %LoadButton
@onready var _quit_btn: Button = %QuitButton
@onready var _options_panel: OptionsPanel = %OptionsPanel
@onready var _save_load_modal: SaveLoadModal = %SaveLoadModal


func _ready() -> void:
	_storm.flash_changed.connect(_on_storm_flash)
	_continue_btn.pressed.connect(_on_continue_pressed)
	%NewGameButton.pressed.connect(func() -> void: _transition_to("res://core/ui/ProtagonistSelect.tscn"))
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
		_transition_to("res://core/overworld/OverworldMap.tscn"))
	_refresh_save_buttons()
	_start_boot_sequence()
	if OS.is_debug_build():
		print("TEST_PASS|title_screen_boot")


func _start_boot_sequence() -> void:
	_state = State.BOOT_SILENCE
	_curtain.modulate.a = 1.0
	_title.modulate.a = 0.0
	_title.offset_top = TITLE_BASE_Y + 10.0
	_subtitle.modulate.a = 0.0
	_press_label.modulate.a = 0.0
	_menu_box.visible = false
	_phase_tween = create_tween()
	_phase_tween.tween_interval(1.2)
	_phase_tween.tween_callback(_start_intro_reveal)


func _start_intro_reveal() -> void:
	_state = State.INTRO_REVEAL
	_kill_tween(_phase_tween)
	_phase_tween = create_tween().set_parallel(true)
	_phase_tween.tween_property(_curtain, "modulate:a", 0.0, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_phase_tween.tween_property(_title, "modulate:a", 1.0, 1.8).set_delay(3.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_phase_tween.tween_property(_title, "offset_top", TITLE_BASE_Y, 1.8).set_delay(3.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_phase_tween.tween_property(_subtitle, "modulate:a", 0.85, 1.0).set_delay(4.8).set_trans(Tween.TRANS_SINE)
	_phase_tween.chain().tween_interval(0.2)
	_phase_tween.chain().tween_callback(_enter_idle_press_start)


func _enter_idle_press_start() -> void:
	_state = State.IDLE_PRESS_START
	_idle_timer = 0.0
	_curtain.modulate.a = 0.0
	_title.modulate.a = 1.0
	_title.offset_top = TITLE_BASE_Y
	_subtitle.modulate.a = 0.85
	_attract_overlay.modulate.a = 0.0
	_storm.set_intro_dim(1.0, 0.6)
	_start_idle_loops()


func _start_idle_loops() -> void:
	_kill_tween(_logo_float_tween)
	_logo_float_tween = create_tween().set_loops()
	_logo_float_tween.tween_property(_title, "offset_top", TITLE_BASE_Y - 2.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_logo_float_tween.tween_property(_title, "offset_top", TITLE_BASE_Y + 2.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_kill_tween(_press_pulse_tween)
	_press_label.modulate.a = 0.35
	_press_pulse_tween = create_tween().set_loops()
	_press_pulse_tween.tween_property(_press_label, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	_press_pulse_tween.tween_property(_press_label, "modulate:a", 0.35, 1.2).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	if _state == State.IDLE_PRESS_START:
		_idle_timer += delta
		if _idle_timer >= IDLE_TO_ATTRACT_SEC:
			_enter_attract_mode()


func _enter_attract_mode() -> void:
	_state = State.ATTRACT_MODE
	_kill_tween(_press_pulse_tween)
	_kill_tween(_attract_tween)
	_attract_label.text = EPIGRAPHIES[_epigraph_idx]
	_epigraph_idx = (_epigraph_idx + 1) % EPIGRAPHIES.size()
	_storm.set_intro_dim(0.75, 1.5)
	_attract_tween = create_tween()
	var fade_out := _attract_tween.set_parallel(true)
	fade_out.tween_property(_title, "modulate:a", 0.0, 1.5)
	fade_out.tween_property(_subtitle, "modulate:a", 0.0, 1.5)
	fade_out.tween_property(_press_label, "modulate:a", 0.0, 1.5)
	_attract_tween.chain().tween_property(_attract_overlay, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	_attract_tween.tween_interval(5.6)
	_attract_tween.tween_property(_attract_overlay, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE)
	_attract_tween.tween_callback(_enter_idle_press_start)


func _unhandled_input(event: InputEvent) -> void:
	var is_press: bool = false
	if event is InputEventKey:
		var k := event as InputEventKey
		is_press = k.pressed and not k.echo
	elif event is InputEventMouseButton:
		is_press = (event as InputEventMouseButton).pressed
	elif event is InputEventJoypadButton:
		is_press = (event as InputEventJoypadButton).pressed
	elif event is InputEventScreenTouch:
		is_press = (event as InputEventScreenTouch).pressed
	if not is_press:
		return
	match _state:
		State.BOOT_SILENCE, State.INTRO_REVEAL:
			_kill_tween(_phase_tween)
			_enter_idle_press_start()
			get_viewport().set_input_as_handled()
		State.ATTRACT_MODE:
			_kill_tween(_attract_tween)
			var tw := create_tween()
			tw.tween_property(_attract_overlay, "modulate:a", 0.0, 0.3)
			tw.tween_callback(_enter_idle_press_start)
			get_viewport().set_input_as_handled()
		State.IDLE_PRESS_START:
			_open_menu_cascade()
			get_viewport().set_input_as_handled()


func _open_menu_cascade() -> void:
	_state = State.MENU_ACTIVE
	_kill_tween(_press_pulse_tween)
	var tw := create_tween()
	tw.tween_property(_press_label, "modulate:a", 0.0, 0.25)
	_menu_box.visible = true
	var idx := 0
	for child: Node in _menu_box.get_children():
		var btn := child as Button
		if btn == null or not btn.visible:
			continue
		btn.modulate.a = 0.0
		var b_tw := create_tween()
		b_tw.tween_property(btn, "modulate:a", 1.0, 0.22).set_delay(float(idx) * 0.08).set_trans(Tween.TRANS_CUBIC)
		idx += 1
	if _continue_btn.visible:
		_continue_btn.grab_focus()
	else:
		%NewGameButton.grab_focus()


func _transition_to(scene_path: String) -> void:
	if _state == State.TRANSITION_OUT:
		return
	_state = State.TRANSITION_OUT
	var tw := create_tween()
	tw.tween_property(_curtain, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file(scene_path))


func _refresh_save_buttons() -> void:
	var has_save := SaveSystem.has_any_save()
	_continue_btn.visible = has_save
	_load_btn.disabled = not has_save


func _on_continue_pressed() -> void:
	var latest := SaveSystem.get_latest_slot()
	if latest >= 0 and SaveSystem.load_slot(latest):
		_transition_to("res://core/overworld/OverworldMap.tscn")


func _on_modal_closed() -> void:
	_menu_box.visible = true
	_refresh_save_buttons()


func _on_storm_flash(intensity: float) -> void:
	_title.self_modulate = Color(0.86, 0.84, 0.78).lerp(Color(1.0, 0.98, 0.94), intensity)


func _kill_tween(tw: Tween) -> void:
	if tw != null and tw.is_valid():
		tw.kill()

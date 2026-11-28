extends Control
## Tela pré-seleção com prólogo filosófico e 7 perguntas sorteadas (1 por domínio).

const BridgeScript := preload("res://core/narrative/archon_trial_bridge.gd")
const ITALIC_FONT := preload("res://core/ui/fonts/LiberationSerif-Italic.ttf")
const DB_TRES_PATH := "res://data/archon_questions_db.tres"
const DB_JSON_PATH := "res://data/archon_questions.json"
const TITLE_SCENE_PATH := "res://core/ui/TitleScreen.tscn"
const PROTAGONIST_SCENE_PATH := "res://core/ui/ProtagonistSelect.tscn"
const CHARS_PER_SEC := 45.0
const PROLOGUE_TEXT := (
	"A jornada do andarilho é tecida de sombras, percalços e escolhas que pesam "
	+ "sobre o espírito. Antes que o caminho se abra, responde em silêncio: "
	+ "qual será tua resolução diante das provações que a teia da vida te impõe?"
)

@onready var _prompt_label: Label = $Panel/Margin/VBox/PromptLabel
@onready var _continue_btn: Button = $Panel/Margin/VBox/ContinueIntroButton
@onready var _choices_box: VBoxContainer = $Panel/Margin/VBox/ChoicesBox
@onready var _back_btn: Button = $Panel/Margin/VBox/BackButton
@onready var _curtain: ColorRect = $BlackCurtain

var _bank: Resource
var _questions: Array = []
var _current_idx: int = -1
var _in_prologue: bool = true
var _is_typing: bool = false
var _transitioning: bool = false
var _type_tween: Tween


func _ready() -> void:
	randomize()
	_bank = _load_bank()
	if _bank != null:
		_questions = _bank.call("draw_seven_archon_trial")
	_continue_btn.pressed.connect(_on_continue_intro)
	_back_btn.pressed.connect(_on_back_pressed)
	_fade_curtain(0.0, 0.55)
	_show_prologue()


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or not _is_typing:
		return
	var is_skip := (
		(event is InputEventMouseButton and event.pressed)
		or (event is InputEventKey and event.pressed and not event.echo)
	)
	if is_skip:
		_finish_typing_immediately()
		get_viewport().set_input_as_handled()


func _load_bank() -> Resource:
	if ResourceLoader.exists(DB_TRES_PATH):
		var loaded := ResourceLoader.load(DB_TRES_PATH)
		if loaded != null:
			return loaded
	return BridgeScript.load_from_json(DB_JSON_PATH)


func _show_prologue() -> void:
	_in_prologue = true
	_clear_choices()
	_choices_box.visible = false
	_continue_btn.visible = false
	_type_text(PROLOGUE_TEXT, func() -> void:
		_continue_btn.modulate.a = 0.0
		_continue_btn.visible = true
		var tw := create_tween()
		tw.tween_property(_continue_btn, "modulate:a", 1.0, 0.25)
	)


func _on_continue_intro() -> void:
	if _transitioning:
		return
	_in_prologue = false
	_continue_btn.visible = false
	_show_question(0)


func _show_question(idx: int) -> void:
	_current_idx = idx
	if _current_idx >= _questions.size():
		_go_to_scene(PROTAGONIST_SCENE_PATH)
		return
	var q: Dictionary = _questions[_current_idx]
	_clear_choices()
	_choices_box.visible = true
	_choices_box.modulate.a = 0.0

	var choices: Array = (q.get("choices", []) as Array).duplicate()
	choices.shuffle()
	var q_id: String = String(q.get("id", ""))
	for ch in choices:
		var btn := _create_choice_button(q_id, ch)
		_choices_box.add_child(btn)

	_type_text(String(q.get("prompt", "")), func() -> void:
		for child in _choices_box.get_children():
			if child is Button:
				(child as Button).disabled = false
		var tw := create_tween()
		tw.tween_property(_choices_box, "modulate:a", 1.0, 0.22)
	)


func _create_choice_button(q_id: String, ch: Dictionary) -> Button:
	var btn := Button.new()
	btn.text = String(ch.get("text", ""))
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.disabled = true
	btn.add_theme_font_override("font", ITALIC_FONT)
	btn.add_theme_font_size_override("font_size", 9)
	btn.add_theme_color_override("font_color", Color(0.9, 0.87, 0.8, 1.0))
	var key := String(ch.get("key", ""))
	btn.pressed.connect(_on_choice_selected.bind(q_id, key))
	return btn


func _type_text(text_content: String, on_done: Callable) -> void:
	if _type_tween != null and _type_tween.is_valid():
		_type_tween.kill()
	_prompt_label.text = text_content
	_prompt_label.visible_characters = 0
	var total := text_content.length()
	if total <= 0:
		_is_typing = false
		on_done.call()
		return
	_is_typing = true
	var duration := maxf(0.35, float(total) / CHARS_PER_SEC)
	_type_tween = create_tween()
	_type_tween.tween_property(_prompt_label, "visible_characters", total, duration)
	_type_tween.finished.connect(func() -> void:
		_is_typing = false
		on_done.call()
	)


func _finish_typing_immediately() -> void:
	if _type_tween != null and _type_tween.is_valid():
		_type_tween.kill()
	_prompt_label.visible_characters = -1
	_is_typing = false
	if _in_prologue:
		_continue_btn.modulate.a = 1.0
		_continue_btn.visible = true
	else:
		for child in _choices_box.get_children():
			if child is Button:
				(child as Button).disabled = false
		_choices_box.modulate.a = 1.0


func _clear_choices() -> void:
	for child in _choices_box.get_children():
		child.queue_free()


func _on_choice_selected(question_id: String, choice_key: String) -> void:
	if _transitioning or _is_typing:
		return
	if _bank != null:
		_bank.call("apply_choice", question_id, choice_key, WorldState, EssenceState)
	_show_question(_current_idx + 1)


func _on_back_pressed() -> void:
	if _transitioning:
		return
	_go_to_scene(TITLE_SCENE_PATH)


func _go_to_scene(path: String) -> void:
	_transitioning = true
	var tw := _fade_curtain(1.0, 0.45)
	tw.finished.connect(func() -> void:
		get_tree().change_scene_to_file(path)
	)


func _fade_curtain(target_alpha: float, duration: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(_curtain, "color:a", target_alpha, duration)
	return tw

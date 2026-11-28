class_name ArchonTrialScreen
extends Control
## Rodada inicial das 7 perguntas (1 por silhueta 01..07) antes da escolha de protagonista.

const ROMAN: Array[String] = ["I", "II", "III", "IV", "V", "VI", "VII"]
const SILHOUETTE_PATHS: Array[String] = [
	"res://core/ui/art/title_silhouettes/01_athoth.jpg",
	"res://core/ui/art/title_silhouettes/02_eloaiou.jpg",
	"res://core/ui/art/title_silhouettes/03_astaphaios.jpg",
	"res://core/ui/art/title_silhouettes/04_yao.jpg",
	"res://core/ui/art/title_silhouettes/05_sabaoth.jpg",
	"res://core/ui/art/title_silhouettes/06_adonin.jpg",
	"res://core/ui/art/title_silhouettes/07_sabbede.jpg",
]

var _bank: ArchonTrialBridge
var _trial: Array[Dictionary] = []
var _index: int = 0
var _busy: bool = false
var _flash_tween: Tween

@onready var _silhouette: TextureRect = %SilhouetteRect
@onready var _step_lbl: Label = %StepLabel
@onready var _prompt_lbl: Label = %PromptLabel
@onready var _choices_box: VBoxContainer = %ChoicesBox
@onready var _curtain: ColorRect = %BlackCurtain


func _ready() -> void:
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	var start_era: String = ProjectSettings.get_setting(WorldState.START_ERA_SETTING, "res://eras/act_01_tianxu/EraConfig_Act01.tres")
	WorldState.load_era(start_era)
	_bank = ArchonTrialBridge.load_from_json("res://data/archon_questions.json")
	_trial = _bank.draw_seven_archon_trial()
	%BackButton.pressed.connect(_on_back_pressed)

	_curtain.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_curtain, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	if _trial.is_empty():
		get_tree().change_scene_to_file.call_deferred("res://core/ui/ProtagonistSelect.tscn")
		return
	_show_question(0)


func _show_question(idx: int) -> void:
	_index = idx
	_busy = false
	var q: Dictionary = _trial[_index]
	_step_lbl.text = "Vigília %s / VII" % ROMAN[mini(_index, ROMAN.size() - 1)]
	_prompt_lbl.text = String(q.get("prompt", ""))
	_load_silhouette(_index)
	_pulse_silhouette(0.68, 0.30, 1.1)

	for child: Node in _choices_box.get_children():
		_choices_box.remove_child(child)
		child.queue_free()
	for ch_var: Variant in q.get("choices", []):
		var ch := ch_var as Dictionary
		var btn := Button.new()
		btn.text = "%s) %s" % [String(ch.get("key", "")), String(ch.get("text", ""))]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 34)
		btn.pressed.connect(_on_choice_pressed.bind(String(q["id"]), String(ch["key"])))
		_choices_box.add_child(btn)


func _load_silhouette(idx: int) -> void:
	var path: String = SILHOUETTE_PATHS[mini(idx, SILHOUETTE_PATHS.size() - 1)]
	if ResourceLoader.exists(path):
		_silhouette.texture = load(path) as Texture2D


func _pulse_silhouette(peak: float, rest: float, decay_sec: float) -> void:
	var mat := _silhouette.material as ShaderMaterial
	if mat == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash_amount", v), 0.12, peak, 0.12)
	_flash_tween.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash_amount", v), peak, rest, decay_sec).set_trans(Tween.TRANS_SINE)


func _on_choice_pressed(question_id: String, choice_key: String) -> void:
	if _busy:
		return
	_busy = true
	_bank.apply_choice(question_id, choice_key, WorldState, EssenceState)
	if _index + 1 >= _trial.size():
		var tw := create_tween()
		tw.tween_property(_curtain, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func() -> void: get_tree().change_scene_to_file("res://core/ui/ProtagonistSelect.tscn"))
	else:
		_show_question(_index + 1)


func _on_back_pressed() -> void:
	if _busy:
		return
	_busy = true
	get_tree().change_scene_to_file("res://core/ui/TitleScreen.tscn")

class_name InterludeController
extends Node2D
## Camada 3 — Interlúdio de Presença: cena 2D em paralaxe + PointLight2D + timeline Dialogic 2.
## A timeline (dados da era) emite [signal arg="effect|chave=valor|..."]; este script só
## interpreta e aplica os efeitos no WorldState. Nenhum texto de diálogo vive aqui.

const EFFECT_PREFIX: String = "effect|"
const INT_KEYS: Array[String] = ["alignment", "popular_support", "doctrine", "resources"]

var timeline_path: String = ""
var title: String = ""
var node_id: String = ""
var applied_effects: Array[Dictionary] = []
var _time: float = 0.0

@onready var _title_label: Label = %Title
@onready var _lantern: PointLight2D = %Lantern
@onready var _ui_root: Control = %UIRoot


func setup(p_timeline_path: String, p_title: String = "", p_node_id: String = "") -> void:
	timeline_path = p_timeline_path
	title = p_title
	node_id = p_node_id


func _ready() -> void:
	var era: EraConfig = WorldState.era_config
	if era:
		_ui_root.theme = era.ui_theme
	_title_label.text = title
	var dialogic: Node = get_node_or_null("/root/Dialogic")
	if dialogic == null or timeline_path.is_empty():
		push_error("InterludeController: Dialogic ausente ou timeline vazia ('%s')" % timeline_path)
		_finish.call_deferred()
		return
	dialogic.connect("signal_event", _on_dialogic_signal)
	dialogic.connect("timeline_ended", _finish)
	dialogic.call("start", timeline_path)
	if OS.is_debug_build():
		print("TEST_PASS|interlude_boot|%s" % timeline_path.get_file())


func _process(delta: float) -> void:
	_time += delta
	# Chama de lanterna determinística (sem RNG).
	_lantern.energy = 1.15 + 0.12 * sin(_time * 7.0) + 0.06 * sin(_time * 17.0)


## Converte "effect|alignment=10|flag=x" em { "alignment": 10, "flag": "x" }.
static func parse_effects(argument: String) -> Dictionary:
	var effects: Dictionary = {}
	if not argument.begins_with(EFFECT_PREFIX):
		return effects
	for pair: String in argument.substr(EFFECT_PREFIX.length()).split("|", false):
		var parts: PackedStringArray = pair.split("=", true, 1)
		if parts.size() != 2:
			continue
		var key: String = parts[0].strip_edges()
		var value: String = parts[1].strip_edges()
		effects[key] = int(value) if key in INT_KEYS else value
	return effects


func apply_signal_argument(argument: String) -> void:
	var effects := parse_effects(argument)
	if effects.is_empty():
		return
	WorldState.apply_effects(effects)
	applied_effects.append(effects)
	EventBus.interlude_choice_applied.emit(effects)


func _on_dialogic_signal(argument: Variant) -> void:
	if argument is String:
		apply_signal_argument(argument)


func _finish() -> void:
	var dialogic: Node = get_node_or_null("/root/Dialogic")
	if dialogic and dialogic.is_connected("signal_event", _on_dialogic_signal):
		dialogic.disconnect("signal_event", _on_dialogic_signal)
		dialogic.disconnect("timeline_ended", _finish)
	EventBus.interlude_finished.emit(timeline_path)
	queue_free()

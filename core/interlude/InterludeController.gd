class_name InterludeController
extends Node2D
## Camada 3 — Interlúdio de Presença: cena 2D em paralaxe + PointLight2D + timeline Dialogic 2.
## A timeline (dados da era) emite [signal arg="effect|chave=valor|..."]; este script só
## interpreta e aplica os efeitos no WorldState. Nenhum texto de diálogo vive aqui.

const EFFECT_PREFIX: String = "effect|"
const INT_KEYS: Array[String] = ["alignment", "popular_support", "doctrine", "resources", "charisma"]

## Sons de digitação do layout de EXEMPLO do Dialogic: desligados até a trilha própria
## (Sprint 4). Ligados, vazam AudioStreamWAV quando o jogo fecha no meio de uma fala.
@export var type_sounds_enabled: bool = false

var timeline_path: String = ""
var title: String = ""
var node_id: String = ""
var applied_effects: Array[Dictionary] = []
var _time: float = 0.0

@onready var _title_label: Label = %Title
@onready var _lantern: PointLight2D = %Lantern
@onready var _ui_root: Control = %UIRoot
@onready var _overlay: ColorRect = %EphemeralOverlay


func setup(p_timeline_path: String, p_title: String = "", p_node_id: String = "") -> void:
	timeline_path = p_timeline_path
	title = p_title
	node_id = p_node_id


func _ready() -> void:
	var era: EraConfig = WorldState.era_config
	if era:
		_ui_root.theme = era.ui_theme
	_overlay.material = InterludeManager.overlay_material(era)
	_overlay.visible = _overlay.material != null
	_title_label.text = title
	var dialogic: Node = get_node_or_null("/root/Dialogic")
	if dialogic == null or timeline_path.is_empty():
		push_error("InterludeController: Dialogic ausente ou timeline vazia ('%s')" % timeline_path)
		_finish.call_deferred()
		return
	dialogic.connect("signal_event", _on_dialogic_signal)
	dialogic.connect("timeline_ended", _finish)
	var layout := dialogic.call("start", timeline_path) as Node
	if layout:
		if not layout.is_node_ready():
			await layout.ready
		_fit_layout(layout, era)
		if not type_sounds_enabled:
			_disable_type_sounds(layout)
	if OS.is_debug_build():
		print("TEST_PASS|interlude_boot|%s" % timeline_path.get_file())


## Ajusta o layout padrão do Dialogic à resolução lógica e à estética da era.
func _fit_layout(root: Node, era: EraConfig) -> void:
	if era == null:
		return
	var overrides: Dictionary = {
		"global_font_size": era.dialogue_font_size,
		"box_size": era.dialogue_box_size,
		"box_margin_bottom": era.dialogue_box_margin_bottom,
		"boxes_v_separation": 4,
	}
	var touched: bool = false
	for key: String in overrides:
		if key in root:
			root.set(key, overrides[key])
			touched = true
	if touched and root.has_method("_apply_export_overrides"):
		root.call("_apply_export_overrides")
	for child: Node in root.get_children():
		_fit_layout(child, era)


func _disable_type_sounds(root: Node) -> void:
	for child: Node in root.get_children():
		if child is DialogicNode_TypeSounds:
			(child as DialogicNode_TypeSounds).enabled = false
		_disable_type_sounds(child)


func _process(delta: float) -> void:
	_time += delta
	# Chama de lanterna determinística (sem RNG).
	_lantern.energy = 1.15 + 0.12 * sin(_time * 7.0) + 0.06 * sin(_time * 17.0)
	if _overlay.visible:  # Encontro efêmero: a cena se desfaz lentamente enquanto acontece.
		(_overlay.material as ShaderMaterial).set_shader_parameter("dissolve", clampf(_time / 90.0, 0.0, 0.85))


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
	# "decision=chave:true|false" grava no estado persistente, uma única vez; repetir é ignorado.
	if effects.has("decision"):
		var parts: PackedStringArray = String(effects["decision"]).split(":")
		if not EssenceState.record_decision(parts[0], parts.size() > 1 and parts[1] == "true"):
			return
	if effects.has("resistance"):
		EssenceState.add_resistance_flag(String(effects["resistance"]))
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
	InterludeManager.mark_played(timeline_path, WorldState.era_config)
	EventBus.interlude_finished.emit(timeline_path)
	queue_free()

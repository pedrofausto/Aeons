extends Node
## Autoload ponte que carrega archon_questions_db.tres e conecta Dialogic.signal_event
## a ArchonTrialBridge.apply_choice() (protegido contra conexões duplicadas).

const BridgeScript := preload("res://core/narrative/archon_trial_bridge.gd")
const DB_TRES_PATH := "res://data/archon_questions_db.tres"
const DB_JSON_PATH := "res://data/archon_questions.json"

var bank: Resource


func _ready() -> void:
	if ResourceLoader.exists(DB_TRES_PATH):
		bank = ResourceLoader.load(DB_TRES_PATH) as Resource
	if bank == null:
		bank = BridgeScript.load_from_json(DB_JSON_PATH)
	var dlg := get_node_or_null("/root/Dialogic")
	if dlg != null and dlg.has_signal("signal_event"):
		if not dlg.is_connected("signal_event", _on_dialogic_signal):
			dlg.connect("signal_event", _on_dialogic_signal)


func _on_dialogic_signal(arg: Variant) -> void:
	var s := String(arg)
	if not s.begins_with("archon_choice:") or bank == null:
		return
	var parts := s.split(":", false)
	if parts.size() >= 3:
		bank.call("apply_choice", parts[1], parts[2], WorldState, EssenceState)

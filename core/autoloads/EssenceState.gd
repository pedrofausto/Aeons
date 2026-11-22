extends Node
## Estado OCULTO persistido entre os 5 atos. Nunca exibido na UI dos Atos I–IV.

var completed_acts: Array[int] = []
var alignment_history: Dictionary = {}   # act_id -> final_alignment
var doctrine_history: Dictionary = {}    # act_id -> final_doctrine
var philosophical_echoes: Array[String] = [] # Ex: ["protected_pengming_charts", "spared_deserters"]
var aeon_resistance_flags: Array[String] = []   # Rupturas de autonomia (ex.: proteger mapas proibidos)
var ephemeral_meetings_seen: Array[String] = [] # Encontros únicos do Ato V (nunca se repetem)
var decisions: Dictionary = {}                  # Escolhas definitivas: { "act1_blind_astronomer_protected": true }


func archive_act_and_reset_visible(act_id: int) -> void:
	if act_id not in completed_acts:
		completed_acts.append(act_id)
	alignment_history[act_id] = WorldState.alignment
	doctrine_history[act_id] = WorldState.doctrine
	for echo_id: String in WorldState.act_echoes:
		if echo_id not in philosophical_echoes:
			philosophical_echoes.append(echo_id)
	# Reseta WorldState para um "novo jogo/novo personagem" após a Derrota Falsa
	var next_config: String = WorldState.era_config.next_era_config if WorldState.era_config else ""
	WorldState.reset_visible(act_id + 1)
	if not next_config.is_empty():
		WorldState.load_era(next_config)
	EventBus.era_transition.emit(act_id, act_id + 1)


## Usado por testes e por "Novo Jogo".
## Grava uma decisão definitiva. Só pode ser gravada UMA vez (true ou false); retorna false se já existia.
func record_decision(key: String, value: bool) -> bool:
	if key.is_empty() or decisions.has(key):
		return false
	decisions[key] = value
	return true


func has_decision(key: String) -> bool:
	return bool(decisions.get(key, false))


func add_resistance_flag(flag: String) -> void:
	if flag not in aeon_resistance_flags:
		aeon_resistance_flags.append(flag)


func mark_ephemeral_meeting(meeting_id: String) -> void:
	if meeting_id not in ephemeral_meetings_seen:
		ephemeral_meetings_seen.append(meeting_id)


func reset_all() -> void:
	completed_acts.clear()
	aeon_resistance_flags.clear()
	decisions.clear()
	ephemeral_meetings_seen.clear()
	alignment_history.clear()
	doctrine_history.clear()
	philosophical_echoes.clear()

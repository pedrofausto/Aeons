extends Node
## Estado OCULTO persistido entre os 5 atos. Nunca exibido na UI dos Atos I–IV.

var completed_acts: Array[int] = []
var alignment_history: Dictionary = {}   # act_id -> final_alignment
var doctrine_history: Dictionary = {}    # act_id -> final_doctrine
var philosophical_echoes: Array[String] = [] # Ex: ["protected_pengming_charts", "spared_deserters"]


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
func reset_all() -> void:
	completed_acts.clear()
	alignment_history.clear()
	doctrine_history.clear()
	philosophical_echoes.clear()

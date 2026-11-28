extends Node
## Estado OCULTO persistido entre os 5 atos. Nunca exibido na UI dos Atos I–IV.

var completed_acts: Array[int] = []
var alignment_history: Dictionary = {}   # act_id -> final_alignment
var doctrine_history: Dictionary = {}    # act_id -> final_doctrine
var philosophical_echoes: Array[String] = [] # Ex: ["protected_pengming_charts", "spared_deserters"]
var aeon_resistance_flags: Array[String] = []   # Rupturas de autonomia (ex.: proteger mapas proibidos)
var ephemeral_meetings_seen: Array[String] = [] # Encontros únicos do Ato V (nunca se repetem)
var act_records: Dictionary = {}                # act_id -> {protagonist, final_*, flags, false_defeat}
var false_defeats: Array[String] = []           # Ex.: "act1_tiandu_eclipse", "act2_montsegur_pyre"
var echo_values: Dictionary = {}                # Ecos com valor: { "act2_philosophy": "awaken_within" }
var decisions: Dictionary = {}                  # Escolhas definitivas: { "act1_blind_astronomer_protected": true }
var protagonist_profile: Dictionary = {}        # Perfil escolhido no início (nome, silhueta, olhos, postura)
var essence_lucidity: int = 50                  # 0..100: lucidez oculta calibrada pelas 7 perguntas e escolhas


func archive_act_and_reset_visible(act_id: int) -> void:
	record_act(act_id)
	var next_config: String = WorldState.era_config.next_era_config if WorldState.era_config else ""
	WorldState.reset_visible(act_id + 1)
	if not next_config.is_empty():
		WorldState.load_era(next_config)
	EventBus.era_transition.emit(act_id, act_id + 1)


## Grava o fim do ato (histórico, ecos, act_records, derrota falsa) sem tocar no estado visível.
func record_act(act_id: int) -> void:
	if act_id not in completed_acts:
		completed_acts.append(act_id)
	alignment_history[act_id] = WorldState.alignment
	doctrine_history[act_id] = WorldState.doctrine
	var era: EraConfig = WorldState.era_config
	var record: Dictionary = {
		"protagonist": era.protagonist_name if era else "",
		"final_alignment": WorldState.alignment, "final_popular_support": WorldState.popular_support,
		"final_doctrine": WorldState.doctrine, "flags": WorldState.active_flags.duplicate(true),
		"faction_trust": WorldState.faction_trust.duplicate(), "false_defeat": era.false_defeat_id if era else "",
	}
	if era:  # Campos extras da era: "echo:<chave>" ou "flag:<flag>".
		for field: String in era.act_record_fields:
			var source: PackedStringArray = String(era.act_record_fields[field]).split(":", true, 1)
			record[field] = get_echo(source[1]) if source[0] == "echo" else WorldState.has_flag(source[1])
	record_act_completion(act_id, record)
	if era and not era.false_defeat_id.is_empty() and era.false_defeat_id not in false_defeats:
		false_defeats.append(era.false_defeat_id)
	for echo_id: String in WorldState.act_echoes:
		if echo_id not in philosophical_echoes:
			philosophical_echoes.append(echo_id)


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
	act_records.clear()
	echo_values.clear()
	false_defeats.clear()
	ephemeral_meetings_seen.clear()
	alignment_history.clear()
	doctrine_history.clear()
	philosophical_echoes.clear()
	protagonist_profile.clear()
	essence_lucidity = 50


## Registro final de um ato (protagonista, eixos finais e campos da era). Mescla se já existir.
func record_act_completion(act_id: int, record: Dictionary) -> void:
	var merged: Dictionary = act_records.get(act_id, {})
	merged.merge(record, true)
	act_records[act_id] = merged


## Eco com valor (ex.: "act2_philosophy" -> "shatter_walls"). O primeiro registro vale.
func record_echo(key: String, value: String) -> bool:
	if echo_values.has(key):
		return false
	echo_values[key] = value
	return true


func get_echo(key: String) -> String:
	return String(echo_values.get(key, ""))


## Nível de contenção: começa em 1 e sobe a cada Derrota Falsa vivida.
func containment_level() -> int:
	return 1 + false_defeats.size()

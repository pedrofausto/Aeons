extends RefCounted
## Ato II — documento completo: Aimeric de Val-Clair, cenas 2.1–2.3, confiança das facções,
## Feras dos Pireneus e a Derrota Falsa de Montségur (registro oculto do ato).

const ERA := "res://eras/act_02_occitania/EraConfig_Act02.tres"
const DLG := "res://eras/act_02_occitania/dialogues/%s.dtl"
const MAP_SCENE := "res://core/overworld/OverworldMap.tscn"
const FORBIDDEN: Array[String] = ["aeon", "simulação", "simulacao", "código", "vidas passadas", "vida passada"]

var _shown: Array[String] = []


func run(t: Node) -> void:
	var failed_before: int = t.failed
	_test_data(t)
	_test_signals(t)
	await _test_chronicle(t, 2, "Nenhuma lâmina a mais esta noite", "awaken_within")
	await _test_chronicle(t, 1, "que jamais esqueçam o preço", "shatter_walls")
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era("res://eras/act_01_tianxu/EraConfig_Act01.tres")
	if t.failed == failed_before:
		print("ACT2_CRONICA_PASS")


func _test_data(t: Node) -> void:
	var era: EraConfig = load(ERA)
	var regions: Array[String] = []
	var by_id: Dictionary = {}
	for data: MapNodeData in era.map_nodes:
		by_id[data.node_id] = data
		if data.region_id not in regions:
			regions.append(data.region_id)
	regions.sort()
	t.check("act2_doc_region_ids", regions == ["act2_albi", "act2_beziers", "act2_carcassonne", "act2_montsegur",
		"act2_tarascon", "act2_toulouse"], str(regions))
	t.check("act2_doc_scene_triggers",
		(by_id["burgo_sao_vicente"] as MapNodeData).liberation_timeline == DLG % "cena_2_1_muralhas"
		and (by_id["montsegur"] as MapNodeData).visit_timeline == DLG % "cena_2_2_vigilia"
		and era.climax_timelines == [DLG % "cena_2_3_queda"] and era.false_defeat_id == "act2_montsegur_pyre"
		and era.protagonist_name == "Aimeric de Val-Clair" and era.chronicle_end_text == "FIM DA CRÔNICA II — A RESISTÊNCIA CAIU.")
	var escort: SquadData = load("res://eras/act_02_occitania/map/squad_escolta_da_inquisicao.tres")
	t.check("act2_doc_escort_opens_vigil", String((escort.outcome_rewards["morale_break"] as Dictionary)["interlude"]) == DLG % "cena_2_2_vigilia"
		and String((escort.outcome_rewards["annihilation"] as Dictionary)["interlude"]) == DLG % "cena_2_2_vigilia")
	var company: SquadData = era.starting_squads[0]
	var names: Array[String] = []
	for unit: UnitInstance in company.units:
		names.append(unit.unit_name)
	t.check("act2_doc_aimeric_leads", company.get_leader().unit_name == "Aimeric" and "Guillem" in names
		and "Bertran" not in names and "Peire" not in names, str(names))
	# Feras dos Pireneus: só à noite, nas trilhas de Montségur, sem impacto moral.
	var beasts: EncounterTable = null
	for resource: Resource in era.encounter_tables:
		if (resource as EncounterTable).region_id == "act2_montsegur":
			beasts = resource
	var entry: EncounterEntry = beasts.entries[0] if beasts else null
	t.check("act2_doc_pyrenean_beasts", entry != null and entry.time_of_day == "night"
		and entry.squad.encounter_tag == "natural_wildlife" and beasts.spawn_nodes == ["montsegur"]
		and not entry.is_available("day", 5.0, "act2_montsegur") and entry.is_available("night", 5.0, "act2_montsegur"))
	var leader := UnitInstance.new()
	leader.class_data = load("res://eras/act_02_occitania/classes/sergent_darmes.tres")
	var player := SquadData.new()
	player.units = [leader]
	var fx: Dictionary = BattleConsequences.compute({"winner": "attacker", "victory_type": "annihilation"},
		player, entry.squad, "attacker")
	t.check("act2_doc_beasts_no_moral_impact", int(fx["alignment"]) == 0 and int(fx["doctrine"]) == 0
		and int(fx["popular_support"]) == 0 and not bool(fx["recruit"]), str(fx))
	var secret_ok: bool = true
	for scene: String in ["cena_2_1_muralhas", "cena_2_2_vigilia", "cena_2_3_queda"]:
		var text: String = FileAccess.get_file_as_string(DLG % scene).to_lower()
		for word: String in FORBIDDEN:
			secret_ok = secret_ok and not text.contains(word)
	t.check("act2_doc_scenes_keep_the_disguise", secret_ok)


func _test_signals(t: Node) -> void:
	WorldState.reset_visible(2)
	EssenceState.reset_all()
	var room := InterludeController.new()
	room.apply_signal_argument("effect|doctrine=+15|alignment=-5|trust=fac_faydits:10|decision=act2_walls_doctrine:true")
	room.apply_signal_argument("effect|doctrine=+15|alignment=-5|trust=fac_faydits:10|decision=act2_walls_doctrine:true")
	t.check("act2_doc_faction_trust", WorldState.doctrine == 15 and int(WorldState.faction_trust.get("fac_faydits", 0)) == 10,
		str(WorldState.faction_trust))
	room.apply_signal_argument("effect|essence_echo=act2_philosophy:awaken_within")
	room.apply_signal_argument("effect|essence_echo=act2_philosophy:shatter_walls")
	t.check("act2_doc_echo_recorded_once", EssenceState.get_echo("act2_philosophy") == "awaken_within")
	room.free()
	WorldState.reset_visible(3)
	t.check("act2_doc_trust_resets_per_act", WorldState.faction_trust.is_empty())


## Joga 2.1 e 2.2 com `choice`, vence o ato e confere o clímax e a Derrota Falsa.
func _test_chronicle(t: Node, choice: int, climax_line: String, echo: String) -> void:
	EssenceState.reset_all()
	WorldState.reset_visible(2)
	WorldState.load_era(ERA)
	var quiet := WorldState.era_config.duplicate() as EraConfig
	quiet.encounter_tables = []
	WorldState.era_config = quiet
	var map := (load(MAP_SCENE) as PackedScene).instantiate() as OverworldMap
	map.auto_tick = false
	t.get_tree().root.add_child(map)
	await t.get_tree().process_frame
	var director: EncounterDirector = map.get_node("%EncounterDirector")
	var dialogic: Node = t.get_node("/root/Dialogic")
	_shown.clear()
	dialogic.get("Text").connect("about_to_show_text", _on_text)
	director.open_interlude(DLG % "cena_2_1_muralhas", "burgo_sao_vicente")
	director.open_interlude(DLG % "cena_2_2_vigilia", "montsegur")  # Na fila: um interlúdio por vez.
	await _drive_all(t, director, choice)
	var revolutionary: bool = choice == 1
	t.check("act2_doc_walls_choice_%d" % choice, WorldState.doctrine == (25 if revolutionary else -25)
		and int(WorldState.faction_trust.get("fac_faydits" if revolutionary else "fac_cathars", 0)) == 10
		and EssenceState.get_echo("act2_philosophy") == echo, "doc=%d trust=%s" % [WorldState.doctrine, WorldState.faction_trust])
	# Vitória do ato: todos os nós do jogador, nenhum esquadrão inimigo fixo.
	for node_id: String in map.nodes:
		WorldState.capture_node(node_id, "player")
	for token: SquadToken in map.tokens.duplicate():
		if token.squad.faction == "enemy":
			map.remove_token(token)
	director.check_victory()
	await _drive_all(t, director, 1)
	dialogic.get("Text").disconnect("about_to_show_text", _on_text)
	var record: Dictionary = EssenceState.act_records.get(2, {})
	t.check("act2_doc_climax_branch_%d" % choice, _shown.any(func(s: String) -> bool: return s.contains(climax_line))
		and _shown.any(func(s: String) -> bool: return s.contains("se perdeu entre as cinzas de Montségur")), str(_shown.size()))
	t.check("act2_doc_false_defeat_%d" % choice, "act2_montsegur_pyre" in EssenceState.false_defeats
		and WorldState.has_flag("chronicle_closed") and WorldState.is_paused and 2 in EssenceState.completed_acts
		and record.get("protagonist") == "Aimeric de Val-Clair" and record.get("philosophy_echo") == echo
		and record.get("tarasque_spared") == false and int(record.get("final_doctrine", 0)) == WorldState.doctrine
		and record.has("final_popular_support") and EssenceState.containment_level() == 2, str(record))
	map.queue_free()
	await t.get_tree().process_frame


func _on_text(info: Dictionary) -> void:
	_shown.append(String(info.get("text", "")))


func _drive_all(t: Node, director: EncounterDirector, choice: int) -> void:
	var dialogic: Node = t.get_node("/root/Dialogic")
	for i: int in 600:
		if director.active_interlude == null:
			await t.get_tree().process_frame
			if director.active_interlude == null:
				return
		var button := dialogic.get("Choices").call("get_choice_button", choice) as Control
		if button != null and button.is_visible_in_tree():
			dialogic.get("Choices").call("select_choice", choice)
		else:
			dialogic.get("Inputs").call("handle_input")
		await t.get_tree().create_timer(0.12).timeout

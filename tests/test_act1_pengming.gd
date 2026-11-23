extends RefCounted
## Ato I — Arquipélago de Pengming: acesso por mar a partir de Linhai, os cinco nós da ilha,
## o dilema do Arquivista Xu no Observatório e o novo interlúdio do Templo do Bambu.

const ACT01 := "res://eras/act_01_tianxu/EraConfig_Act01.tres"
const MAP_SCENE := "res://core/overworld/OverworldMap.tscn"
const DLG := "res://eras/act_01_tianxu/dialogues/%s.dtl"
const ISLAND: Array[String] = ["cais_neblina", "gruta_jade", "santuarios_bambu", "ponte_mare", "observatorio_nove_ceus"]
const FORBIDDEN: Array[String] = ["aeon", "simulação", "simulacao", "simulacro", "matriz", "concêntric", "vidas passadas"]


func run(t: Node) -> void:
	var failed_before: int = t.failed
	_test_data(t)
	_test_political_charts(t)
	await _test_temple(t)
	await _test_boatman(t)
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	if t.failed == failed_before:
		print("ACT1_PENGMING_PASS")


func _test_data(t: Node) -> void:
	var era: EraConfig = load(ACT01)
	var by_id: Dictionary = {}
	var graph: Dictionary = {}
	for data: MapNodeData in era.map_nodes:
		by_id[data.node_id] = data
		graph[data.node_id] = data.neighbors
	var island_ok: bool = true
	for id: String in ISLAND:
		var d: MapNodeData = by_id.get(id)
		island_ok = island_ok and d != null and d.region_id == "pengming" and not d.required_for_victory
	var strait: MapNodeData = by_id.get("estreito_linhai")
	t.check("pengming_island_nodes", island_ok and strait != null and strait.node_type == MapNodeData.NodeType.SEA
		and "estreito_linhai" in (by_id["linhai"] as MapNodeData).neighbors and strait.neighbors == ["linhai", "cais_neblina"])
	# Só se chega por mar: sem o Estreito, a ilha fica isolada do continente.
	var no_sea: Dictionary = graph.duplicate(true)
	no_sea.erase("estreito_linhai")
	for id: String in no_sea:
		no_sea[id] = (no_sea[id] as Array).filter(func(n: String) -> bool: return n != "estreito_linhai")
	t.check("pengming_only_by_sea", MapGraph.find_path(graph, "linhai", "observatorio_nove_ceus")
		== ["estreito_linhai", "cais_neblina", "santuarios_bambu", "ponte_mare", "observatorio_nove_ceus"]
		and MapGraph.find_path(no_sea, "linhai", "observatorio_nove_ceus").is_empty())
	t.check("pengming_dilemma_moved", (by_id["observatorio_nove_ceus"] as MapNodeData).liberation_timeline == DLG % "o_astronomo_cego"
		and (by_id["templo_bambu"] as MapNodeData).liberation_timeline == DLG % "o_caminho_do_templo"
		and (by_id["cais_neblina"] as MapNodeData).liberation_timeline == DLG % "o_barqueiro_da_neblina")
	var corsairs: SquadData = (by_id["gruta_jade"] as MapNodeData).garrison
	var expedition: SquadData = (by_id["ponte_mare"] as MapNodeData).garrison
	t.check("pengming_garrisons", corsairs != null and expedition != null and expedition.get_leader().class_data.class_id == "intrigante_legalista"
		and String((corsairs.outcome_rewards["annihilation"] as Dictionary)["item"]).ends_with("elixir_pengming.tres")
		and String((corsairs.outcome_rewards["morale_break"] as Dictionary)["item"]).ends_with("elixir_pengming.tres"))
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	var boss_table := load("res://eras/act_01_tianxu/encounters/pengming_encounters.tres") as EncounterTable
	var rng := RandomNumberGenerator.new()
	t.check("pengming_guardian_waits_for_xu", boss_table.pick(rng, "night", 5.0, "pengming") == null)
	var catalog: Array[String] = []
	for item: ItemData in era.item_catalog:
		catalog.append(item.item_id)
	t.check("pengming_items_cataloged", "carta_celeste" in catalog and "elixir_pengming" in catalog)
	var secret_ok: bool = true
	for scene: String in ["o_astronomo_cego", "o_caminho_do_templo", "o_barqueiro_da_neblina"]:
		var text: String = FileAccess.get_file_as_string(DLG % scene).to_lower()
		for word: String in FORBIDDEN:
			secret_ok = secret_ok and not text.contains(word)
	t.check("pengming_scenes_keep_the_disguise", secret_ok)


## Opção "arma política": Apoio dispara e os Caçadores Cike passam a rondar Nanlu.
func _test_political_charts(t: Node) -> void:
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	EssenceState.reset_all()
	var nanlu := load("res://eras/act_01_tianxu/encounters/nanlu_encounters.tres") as EncounterTable
	var hunters: EncounterEntry = null
	for entry: EncounterEntry in nanlu.entries:
		if entry.squad.squad_id == "cacadores_cike":
			hunters = entry
	var hidden: bool = hunters != null and not hunters.is_available("day", 3.0, "nanlu")
	var room := InterludeController.new()
	room.apply_signal_argument("effect|decision=act1_blind_astronomer_protected:true|popular_support=+20|doctrine=+15|flag=act1_charts_published|essence_echo=act1_sky_grid:rupture")
	room.free()
	t.check("pengming_charts_published", hidden and hunters.is_available("day", 3.0, "nanlu") and WorldState.popular_support == 70
		and WorldState.doctrine == 15 and EssenceState.get_echo("act1_sky_grid") == "rupture")


## Templo do Bambu: a fala do Abade Zhuo segue o caminho já trilhado (ou pede uma escolha).
func _test_temple(t: Node) -> void:
	for case: Array in [[20, 1, "act1_temple_red_ribbon", 25, 50], [-20, 1, "act1_temple_tea", -20, 55], [0, 2, "act1_temple_tea", -10, 50]]:
		var map: OverworldMap = await _fresh_map(t)
		WorldState.change_doctrine(int(case[0]))
		var director: EncounterDirector = map.get_node("%EncounterDirector")
		director.open_interlude(DLG % "o_caminho_do_templo", "templo_bambu")
		await _drive_all(t, director, int(case[1]))
		t.check("temple_path_%d" % int(case[0]), WorldState.has_flag(String(case[2])) and WorldState.doctrine == int(case[3])
			and WorldState.alignment == int(case[4]), "doc=%d al=%d" % [WorldState.doctrine, WorldState.alignment])
		map.queue_free()
		await t.get_tree().process_frame


## Barqueiro: pagar a passagem fere a Expedição da Regência na Ponte da Maré.
func _test_boatman(t: Node) -> void:
	var map: OverworldMap = await _fresh_map(t)
	var expedition: SquadData = null
	for token: SquadToken in map.tokens:
		if token.squad.squad_id == "expedicao_regencia":
			expedition = token.squad
	var director: EncounterDirector = map.get_node("%EncounterDirector")
	director.open_interlude(DLG % "o_barqueiro_da_neblina", "cais_neblina")
	await _drive_all(t, director, 1)
	t.check("pengming_boatman_tide_route", expedition != null and WorldState.has_flag("pengming_tide_route")
		and WorldState.resources == 420
		and expedition.units.all(func(u: UnitInstance) -> bool: return u.hp > 1 and u.hp <= u.get_max_hp() * 7 / 10 + 1), "ouro=%d" % WorldState.resources)
	map.queue_free()
	await t.get_tree().process_frame


func _fresh_map(t: Node) -> OverworldMap:
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	WorldState.set_flag("liberated_linhai")
	var quiet := WorldState.era_config.duplicate() as EraConfig
	quiet.encounter_tables = []
	WorldState.era_config = quiet
	var map := (load(MAP_SCENE) as PackedScene).instantiate() as OverworldMap
	map.auto_tick = false
	t.get_tree().root.add_child(map)
	await t.get_tree().process_frame
	return map


func _drive_all(t: Node, director: EncounterDirector, choice: int) -> void:
	var dialogic: Node = t.get_node("/root/Dialogic")
	for i: int in 400:
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

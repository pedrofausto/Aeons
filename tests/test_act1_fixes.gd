extends RefCounted
## Regressões das 3 correções do Ato I: Hanmen + Cortejo noturno, Astrônomo Cego e
## promoção que consome o Talismã de Cinábrio. Emite ACT1_FIXES_SMOKE_PASS.

const MAP_SCENE := "res://core/overworld/OverworldMap.tscn"
const ACT01 := "res://eras/act_01_tianxu/EraConfig_Act01.tres"


func run(t: Node) -> void:
	var failed_before: int = t.failed
	await _test_hanmen(t)
	for method: String in ["_test_astronomer", "_test_talisman_promotion"]:
		if has_method(method):
			await call(method, t)
	if t.failed == failed_before:
		print("ACT1_FIXES_SMOKE_PASS")


func _reset() -> void:
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	WorldState.set_flag("liberated_linhai")


func _open_map(t: Node) -> OverworldMap:
	var map := (load(MAP_SCENE) as PackedScene).instantiate() as OverworldMap
	map.auto_tick = false
	t.get_tree().root.add_child(map)
	await t.get_tree().process_frame
	return map


## (a) Cortejo só em Hanmen e só à noite; nós novos na borda oeste de Nanlu.
func _test_hanmen(t: Node) -> void:
	_reset()
	var map: OverworldMap = await _open_map(t)
	var pass_node: MapNodeData = (map.nodes["hanmen_pass"] as MapNode).data
	var gate_node: MapNodeData = (map.nodes["hanmen_gate"] as MapNode).data
	t.check("hanmen_nodes_west_of_nanlu", pass_node.region_id == "hanmen" and pass_node.terrain == "mountain"
		and gate_node.region_id == "hanmen" and gate_node.node_type == MapNodeData.NodeType.FORTRESS
		and "hanmen_pass" in (map.nodes["linhai"] as MapNode).data.neighbors
		and pass_node.map_position.x < (map.nodes["linhai"] as MapNode).data.map_position.x
		and MapGraph.find_path(map.call("_graph"), "linhai", "hanmen_gate") == ["hanmen_pass", "hanmen_gate"])
	var wei_bo_on_gate: bool = false
	for token: SquadToken in map.tokens:
		if token.squad.squad_id == "guarda_de_hanmen" and token.squad.current_node_id == "hanmen_gate":
			wei_bo_on_gate = token.squad.get_leader().unit_name == "General Wei Bo"
	t.check("hanmen_gate_boss_garrison", wei_bo_on_gate)

	var cortejo_spawns: Array[String] = []
	var other_spawns: int = 0
	for day: int in 60:
		for time: String in ["day", "night"]:
			WorldState.day_count = 2 + day
			WorldState.time_of_day = time
			for squad: SquadData in map.spawner.try_spawn():
				if squad.squad_id == "cortejo_de_jiangshi":
					var region: String = (map.nodes[squad.current_node_id] as MapNode).data.region_id
					cortejo_spawns.append("%s@%s" % [region, time])
				else:
					other_spawns += 1
			for token: SquadToken in map.tokens.duplicate():
				if token.squad.is_roaming:
					map.remove_token(token)
	t.check("cortejo_spawns_only_hanmen_at_night", not cortejo_spawns.is_empty()
		and cortejo_spawns.all(func(s: String) -> bool: return s == "hanmen@night") and other_spawns > 0,
		"cortejos=%s outros=%d" % [str(cortejo_spawns.slice(0, 6)), other_spawns])
	var nanlu := load("res://eras/act_01_tianxu/encounters/nanlu_encounters.tres") as EncounterTable
	var in_nanlu: bool = false
	for entry: EncounterEntry in nanlu.entries:
		in_nanlu = in_nanlu or entry.squad.squad_id == "cortejo_de_jiangshi"
	t.check("cortejo_removed_from_nanlu", not in_nanlu)
	var hanmen := load("res://eras/act_01_tianxu/encounters/hanmen_encounters.tres") as EncounterTable
	var rng := RandomNumberGenerator.new()
	t.check("cortejo_entry_requires_hanmen_night", hanmen.pick(rng, "night", 3.0, "hanmen") != null
		and hanmen.pick(rng, "day", 3.0, "hanmen") == null and hanmen.pick(rng, "night", 3.0, "nanlu") == null)

	var ally: SquadToken = map.selected_token
	var plains: float = ally.march_speed(55.0, "plains")
	t.check("mountain_terrain_slows_march", is_equal_approx(ally.march_speed(55.0, "mountain"), plains * SquadToken.MOUNTAIN_FACTOR))
	for token: SquadToken in map.tokens.duplicate():
		if not token.is_player() and token.squad.squad_id != "guarda_de_hanmen":
			map.remove_token(token)
	WorldState.capture_node("forte_regencia", "player")
	map.get_node("%EncounterDirector").call("check_victory")
	t.check("hanmen_gate_optional_for_victory", WorldState.has_flag("act_victory"))
	map.queue_free()
	await t.get_tree().process_frame

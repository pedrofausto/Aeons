extends RefCounted
## Testes do Mapa de Conquista: pausa (Space), marcha, captura, tick, patrulha,
## colisão -> BattleArena -> retorno ao mapa, até a vitória do ato.

const MAP_SCENE := "res://core/overworld/OverworldMap.tscn"
const ACT01 := "res://eras/act_01_tianxu/EraConfig_Act01.tres"

var battles: Array[Dictionary] = []


func run(t: Node) -> void:
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	WorldState.set_flag("liberated_linhai")  # Interlúdio é coberto em test_interlude.gd

	var graph := {"a": ["b"], "b": ["a", "c"], "c": ["b"]}
	t.check("map_graph_bfs", MapGraph.find_path(graph, "a", "c") == ["b", "c"] and MapGraph.find_path(graph, "a", "a").is_empty())
	var patrol_data := SquadData.new()
	patrol_data.patrol_route = ["a", "b", "c"]
	patrol_data.current_node_id = "c"
	t.check("patrol_ai_loops", PatrolAI.next_leg(patrol_data, graph) == ["b", "a"])

	var map := (load(MAP_SCENE) as PackedScene).instantiate() as OverworldMap
	map.auto_tick = false
	t.get_tree().root.add_child(map)
	await t.get_tree().process_frame

	t.check("overworld_four_nodes", map.nodes.size() == 4 and map.tokens.size() == 3, "tokens=%d" % map.tokens.size())
	t.check("overworld_initial_factions", WorldState.get_node_faction("linhai") == "player"
		and WorldState.get_node_faction("aldeia_terracos") == "neutral"
		and WorldState.get_node_faction("templo_bambu") == "neutral"
		and WorldState.get_node_faction("forte_regencia") == "enemy")
	t.check("overworld_starts_paused", WorldState.is_paused)

	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	Input.parse_input_event(space)
	await t.get_tree().process_frame
	t.check("overworld_space_unpauses", not WorldState.is_paused)

	var ally: SquadToken = map.selected_token
	var patrol: SquadToken = null
	for token: SquadToken in map.tokens:
		if token.squad.is_patrol():
			patrol = token
	t.check("overworld_player_selected", ally != null and ally.is_player() and patrol != null)
	t.check("overworld_order_move", map.order_move(ally, "aldeia_terracos") and ally.path == ["aldeia_terracos"])
	var patrol_start: Vector2 = patrol.position
	_simulate(map, 3.0)
	t.check("patrol_marches", patrol.position != patrol_start)
	_simulate(map, 2.0)
	t.check("overworld_capture_neutral", WorldState.get_node_faction("aldeia_terracos") == "player",
		WorldState.get_node_faction("aldeia_terracos"))
	_simulate(map, 2.0)
	t.check("overworld_day_tick_income", WorldState.day_count >= 2 and WorldState.resources > 500,
		"dia=%d ouro=%d" % [WorldState.day_count, WorldState.resources])

	var director: EncounterDirector = map.get_node("%EncounterDirector")
	if not director.is_busy():
		WorldState.set_paused(true)
		var paused_position: Vector2 = ally.position
		map.order_move(ally, "forte_regencia")
		_simulate(map, 2.0)
		t.check("overworld_pause_freezes_march", ally.position == paused_position)
		WorldState.set_paused(false)

	# Marcha até o forte resolvendo cada encontro (patrulha e/ou guarnição) com Focar Fraco.
	var xp_before: int = _total_xp(ally.squad)
	for attempt: int in 8:
		if WorldState.has_flag("act_victory"):
			break
		if not director.is_busy():
			t.check("battle_leaves_map_paused_%d" % attempt, attempt == 0 or WorldState.is_paused)
			WorldState.set_paused(false)
			if attempt > 0:  # Descanso de 5 dias num nó aliado antes de novo ataque.
				var fatigue_before: int = ally.squad.fatigue
				_simulate(map, map.seconds_per_day * 5.0)
				t.check("rest_recovers_%d" % attempt, ally.squad.fatigue < fatigue_before or fatigue_before == 0)
			map.order_move(ally, "forte_regencia")
			_simulate(map, 15.0)
		if director.active_battle:
			if battles.is_empty():
				t.check("overworld_collision_opens_battle", not map.visible and WorldState.is_paused)
			await _resolve_battle(t, director.active_battle)
			t.check("battle_returns_to_map_%d" % battles.size(), director.active_battle == null and map.visible)
	t.check("battle_updates_world_state", battles.size() >= 2 and ally.squad.fatigue >= 0
		and _total_xp(ally.squad) > xp_before, "batalhas=%d" % battles.size())
	t.check("battle_win_captures_fort", WorldState.get_node_faction("forte_regencia") == "player"
		and WorldState.has_flag("act_victory") and map.tokens.size() == 1)
	print("INFO|batalhas no mapa -> %s" % str(battles.map(func(r: Dictionary) -> String:
		return "%s/%s" % [r["winner"], r["victory_type"]])))

	map.queue_free()
	await t.get_tree().process_frame
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)


func _resolve_battle(t: Node, arena: BattleArena) -> void:
	arena.step_seconds = 0.0
	await arena.start_battle(TacticalOrder.Order.FOCUS_WEAK)
	battles.append(arena.result)
	arena.closed.emit(arena.result)
	await t.get_tree().process_frame


func _simulate(map: OverworldMap, seconds: float) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds and not map.get_node("%EncounterDirector").call("is_busy"):
		map.step(0.05)
		elapsed += 0.05


func _total_xp(squad: SquadData) -> int:
	var total: int = 0
	for unit: UnitInstance in squad.units:
		total += unit.level * UnitInstance.XP_PER_LEVEL + unit.experience
	return total

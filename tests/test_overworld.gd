extends RefCounted
## Testes do Mapa de Conquista: pausa (Space), marcha, captura, tick, colisão -> BattleArena.

const MAP_SCENE := "res://core/overworld/OverworldMap.tscn"
const ACT01 := "res://eras/act_01_tianxu/EraConfig_Act01.tres"


func run(t: Node) -> void:
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	WorldState.set_flag("liberated_linhai")  # Interlúdio é coberto em test_interlude.gd

	var graph := {"a": ["b"], "b": ["a", "c"], "c": ["b"]}
	t.check("map_graph_bfs", MapGraph.find_path(graph, "a", "c") == ["b", "c"] and MapGraph.find_path(graph, "a", "a").is_empty())

	var map := (load(MAP_SCENE) as PackedScene).instantiate() as OverworldMap
	map.auto_tick = false
	t.get_tree().root.add_child(map)
	await t.get_tree().process_frame

	t.check("overworld_four_nodes", map.nodes.size() == 4 and map.tokens.size() == 2)
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
	t.check("overworld_player_selected", ally != null and ally.is_player())
	t.check("overworld_order_move", map.order_move(ally, "aldeia_terracos") and ally.path == ["aldeia_terracos"])
	_simulate(map, 8.0)
	t.check("overworld_capture_neutral", WorldState.get_node_faction("aldeia_terracos") == "player"
		and ally.squad.current_node_id == "aldeia_terracos", WorldState.get_node_faction("aldeia_terracos"))
	t.check("overworld_day_tick_income", WorldState.day_count >= 2 and WorldState.resources > 500,
		"dia=%d ouro=%d" % [WorldState.day_count, WorldState.resources])

	WorldState.set_paused(true)
	var paused_position: Vector2 = ally.position
	map.order_move(ally, "forte_regencia")
	_simulate(map, 2.0)
	t.check("overworld_pause_freezes_march", ally.position == paused_position)
	WorldState.set_paused(false)

	_simulate(map, 12.0)
	var director: EncounterDirector = map.get_node("%EncounterDirector")
	var arena: BattleArena = director.active_battle
	t.check("overworld_collision_opens_battle", arena != null and not map.visible and WorldState.is_paused)
	if arena == null:
		map.queue_free()
		return

	arena.step_seconds = 0.0
	var xp_before: int = _total_xp(ally.squad)
	await arena.start_battle(TacticalOrder.Order.FOCUS_WEAK)
	var result: Dictionary = arena.result
	t.check("battle_arena_result", result.get("type") == "result", str(result))
	arena.closed.emit(result)
	await t.get_tree().process_frame
	t.check("battle_returns_to_map", director.active_battle == null and map.visible)
	t.check("battle_updates_world_state", ally.squad.fatigue > 0 and _total_xp(ally.squad) > xp_before,
		"fadiga=%d xp=%d->%d" % [ally.squad.fatigue, xp_before, _total_xp(ally.squad)])
	if bool(result["effects"]["player_won"]):
		t.check("battle_win_captures_fort", WorldState.get_node_faction("forte_regencia") == "player"
			and WorldState.has_flag("act_victory") and map.tokens.size() == 1)
	else:
		t.check("battle_loss_retreats", WorldState.get_node_faction(ally.squad.current_node_id) == "player")
	print("INFO|overworld battle -> %s" % str(result.get("victory_type")))

	map.queue_free()
	await t.get_tree().process_frame
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)


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

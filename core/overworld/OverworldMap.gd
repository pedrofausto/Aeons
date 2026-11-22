class_name OverworldMap
extends Node2D
## Mapa em tempo real com pausa tática (Space). Constrói nós e esquadrões a partir do
## EraConfig ativo, move tokens pelo grafo e abre a BattleArena ao colidirem.

const COLLISION_DISTANCE: float = 15.0
const REST_PERCENT_PER_DAY: int = 10

@export var march_speed: float = 55.0           # px/s (resolução lógica 640x360)
@export var seconds_per_day: float = 6.0
@export var auto_tick: bool = true              # false em testes (avança via step())

var nodes: Dictionary = {}                      # node_id -> MapNode
var tokens: Array[SquadToken] = []
var selected_token: SquadToken
var _day_timer: float = 0.0

@onready var _roads: Node2D = %Roads
@onready var _nodes_root: Node2D = %Nodes
@onready var _tokens_root: Node2D = %Tokens
@onready var _hud: OverworldHUD = %HUD
@onready var _director: EncounterDirector = %EncounterDirector


func _ready() -> void:
	var era: EraConfig = WorldState.era_config
	(%Background as ColorRect).color = era.color_background
	_hud.pause_pressed.connect(toggle_pause)
	_hud.promote_pressed.connect(_on_promote)
	_hud.debug_transition_pressed.connect(_on_debug_transition)
	_director.setup(self)
	_build_map(era)
	_roads.draw.connect(_draw_roads)
	_roads.queue_redraw()
	_hud.show_banner("" if not era.map_nodes.is_empty() else era.era_title)
	WorldState.set_paused(true)
	_hud.refresh()
	_director.check_liberations.call_deferred()
	if OS.is_debug_build():
		print("TEST_PASS|overworld_boot|nodes=%d|tokens=%d" % [nodes.size(), tokens.size()])


func _build_map(era: EraConfig) -> void:
	var fresh_act: bool = WorldState.captured_nodes.is_empty()
	for data: MapNodeData in era.map_nodes:
		if fresh_act:
			WorldState.captured_nodes[data.node_id] = data.faction
		var view := MapNode.new()
		_nodes_root.add_child(view)
		view.setup(data, WorldState.get_node_faction(data.node_id))
		nodes[data.node_id] = view
		if data.garrison and WorldState.get_node_faction(data.node_id) == "enemy":
			var garrison := data.garrison.clone()
			garrison.current_node_id = data.node_id
			_spawn_token(garrison)
	if fresh_act:
		for patrol: SquadData in era.enemy_patrols:
			_spawn_token(patrol.clone())
		WorldState.player_squads.clear()
		for template: SquadData in era.starting_squads:
			WorldState.player_squads.append(template.clone())
	for squad: SquadData in WorldState.player_squads:
		_spawn_token(squad)
	for token: SquadToken in tokens:
		if token.is_player():
			_select(token)
			break


func _spawn_token(squad: SquadData) -> SquadToken:
	var token := SquadToken.new()
	_tokens_root.add_child(token)
	token.setup(squad, nodes[squad.current_node_id].position)
	token.arrived.connect(_on_token_arrived)
	tokens.append(token)
	return token


# --- Entrada ---------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _is_busy():
		return
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_SPACE:
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_handle_click(get_global_mouse_position())
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if not _is_busy():
		WorldState.set_paused(not WorldState.is_paused)


func _handle_click(point: Vector2) -> void:
	for token: SquadToken in tokens:
		if token.is_player() and token.contains_point(point):
			_select(token)
			return
	for node_id: String in nodes:
		if (nodes[node_id] as MapNode).contains_point(point) and selected_token:
			order_move(selected_token, node_id)
			return


func _select(token: SquadToken) -> void:
	if selected_token:
		selected_token.selected = false
	selected_token = token
	token.selected = true


## Ordena a marcha até `target_id` pelo menor caminho do grafo (BFS determinística).
func order_move(token: SquadToken, target_id: String) -> bool:
	var origin: String = token.path[0] if token.is_moving() else token.squad.current_node_id
	var route := MapGraph.find_path(_graph(), origin, target_id)
	if route.is_empty() and origin != target_id:
		return false
	if origin != token.squad.current_node_id or token.is_moving():
		route.push_front(origin)
	token.set_path(route)
	return true


# --- Marcha em tempo real -----------------------------------------------

func _process(delta: float) -> void:
	if auto_tick:
		step(delta)


func step(delta: float) -> void:
	if WorldState.is_paused or _is_busy():
		return
	var positions: Dictionary = {}
	for node_id: String in nodes:
		positions[node_id] = (nodes[node_id] as MapNode).position
	for token: SquadToken in tokens.duplicate():
		if token.squad.is_patrol() and not token.is_moving():
			token.set_path(PatrolAI.next_leg(token.squad, _graph()))
		token.advance(delta, march_speed * (PatrolAI.SPEED_FACTOR if token.squad.is_patrol() else 1.0), positions)
		if _is_busy():
			return
	_check_collisions()
	_day_timer += delta
	if _day_timer >= seconds_per_day:
		_day_timer -= seconds_per_day
		_on_new_day()


func _on_new_day() -> void:
	WorldState.advance_day()
	var income: int = 0
	for node_id: String in nodes:
		if WorldState.get_node_faction(node_id) == "player":
			income += (nodes[node_id] as MapNode).data.gold_per_tick
	WorldState.change_resources(income)
	for token: SquadToken in tokens:
		if token.is_player() and not token.is_moving() \
				and WorldState.get_node_faction(token.squad.current_node_id) == "player":
			token.squad.rest(REST_PERCENT_PER_DAY)
	EventBus.tick_advanced.emit(WorldState.day_count)


func _check_collisions() -> void:
	for ally: SquadToken in tokens:
		if not ally.is_player():
			continue
		for foe: SquadToken in tokens:
			if foe.squad.faction == "enemy" and ally.get_anchor().distance_to(foe.get_anchor()) <= COLLISION_DISTANCE:
				_director.start_battle(ally, foe)
				return


func _on_token_arrived(token: SquadToken, node_id: String) -> void:
	if not token.is_player() or WorldState.get_node_faction(node_id) == "player":
		return
	for other: SquadToken in tokens:
		if other.squad.faction == "enemy" and other.squad.current_node_id == node_id:
			return  # Ainda defendido: a colisão resolve.
	capture(node_id)


func capture(node_id: String) -> void:
	WorldState.capture_node(node_id, "player")
	(nodes[node_id] as MapNode).set_faction("player")
	_director.check_liberations()
	_director.check_victory()


func _graph() -> Dictionary:
	var graph: Dictionary = {}
	for node_id: String in nodes:
		graph[node_id] = (nodes[node_id] as MapNode).data.neighbors
	return graph


func _is_busy() -> bool:
	return _director.is_busy()


func _draw_roads() -> void:
	var color: Color = WorldState.era_config.color_road
	for node_id: String in nodes:
		var from: MapNode = nodes[node_id]
		for next_id: String in from.data.neighbors:
			if nodes.has(next_id) and node_id < next_id:
				_roads.draw_line(from.position, (nodes[next_id] as MapNode).position, color, 3.0)


func remove_token(token: SquadToken) -> void:
	tokens.erase(token)
	if selected_token == token:
		selected_token = null
	token.queue_free()


## Chamado pelo EncounterDirector depois que a BattleArena fecha.
func on_encounter_resolved() -> void:
	_director.check_victory()
	_hud.refresh()


func show_banner(text: String) -> void:
	_hud.show_banner(text)


func _on_promote() -> void:
	var done: Array[String] = []
	for squad: SquadData in WorldState.player_squads:
		done.append_array(squad.promote_eligible())
	_hud.show_banner("\n".join(done))
	_hud.refresh()


## Debug (apenas desenvolvimento): "Derrota Falsa" -> arquiva o ato e recarrega o mapa.
func _on_debug_transition() -> void:
	if _is_busy():
		return
	EssenceState.archive_act_and_reset_visible(WorldState.current_act)
	get_tree().reload_current_scene()

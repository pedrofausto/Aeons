class_name EncounterDirector
extends Node
## Abre e fecha as camadas 2 (BattleArena) e 3 (InterludeRoom) sobre o mapa.
## Enquanto uma delas está ativa, o overworld fica pausado e oculto.

const BATTLE_SCENE: PackedScene = preload("res://core/combat/BattleArena.tscn")
const INTERLUDE_SCENE_PATH: String = "res://core/interlude/InterludeRoom.tscn"

var map: OverworldMap
var active_battle: BattleArena
var active_interlude: Node
var _queue: Array[String] = []          # Interlúdios em fila (clímax do ato)
var _after_queue: Callable
var _ally_token: SquadToken
var _foe_token: SquadToken


func setup(p_map: OverworldMap) -> void:
	map = p_map
	EventBus.interlude_requested.connect(open_interlude)
	EventBus.player_squad_formed.connect(func(squad: SquadData) -> void:
		if map.nodes.has(squad.current_node_id):
			map.spawn_token(squad))


func is_busy() -> bool:
	return active_battle != null or active_interlude != null


func start_battle(ally: SquadToken, foe: SquadToken) -> void:
	_ally_token = ally
	_foe_token = foe
	ally.path.clear()
	WorldState.set_paused(true)
	var foe_node: MapNode = map.nodes.get(foe.squad.current_node_id)
	var context: Dictionary = {"node_id": foe.squad.current_node_id, "player_side": "attacker",
		"terrain": foe_node.data.terrain if foe_node else "plains"}
	EventBus.battle_requested.emit(ally.squad, foe.squad, context)
	active_battle = BATTLE_SCENE.instantiate() as BattleArena
	active_battle.setup(ally.squad, foe.squad, context)
	active_battle.closed.connect(_on_battle_closed)
	_set_map_visible(false)
	map.get_tree().root.add_child(active_battle)


func _on_battle_closed(result: Dictionary) -> void:
	var effects: Dictionary = result.get("effects", {})
	var report: Dictionary = BattleConsequences.apply(effects, _ally_token.squad, _foe_token.squad)
	var notes: Array[String] = []
	if not String(report["recruited"]).is_empty():
		notes.append(WorldState.era_config.recruit_message % [report["recruited"], _ally_token.squad.display_name])
	for item_name: String in report["items"]:
		notes.append(WorldState.era_config.item_message % item_name)
	if not notes.is_empty():
		map.show_banner("\n".join(notes), 4.0)
	var reward_interlude: String = String(report.get("interlude", ""))
	if bool(effects.get("player_won", false)):
		var node_id: String = _foe_token.squad.current_node_id
		var was_patrol: bool = _foe_token.squad.is_patrol()
		map.remove_token(_foe_token)
		if was_patrol:  # Patrulha batida na estrada: o esquadrão volta ao último nó visitado.
			node_id = _ally_token.squad.current_node_id
		else:
			map.capture(node_id, _ally_token.squad)
		_ally_token.teleport_to(node_id, map.nodes[node_id].position)
	else:
		_foe_token.squad.restore_morale()
		var retreat: String = _nearest_player_node(_ally_token.position)
		if not retreat.is_empty():
			_ally_token.teleport_to(retreat, map.nodes[retreat].position)
		if _ally_token.squad.is_annihilated():
			_ally_token.squad.rest(30)
	active_battle.queue_free()
	active_battle = null
	_set_map_visible(true)
	map.on_encounter_resolved()
	if not reward_interlude.is_empty() and not is_busy():
		open_interlude(reward_interlude, _ally_token.squad.current_node_id)


func open_interlude(timeline_path: String, node_id: String) -> void:
	if is_busy():  # Um interlúdio por vez: o próximo espera na fila.
		if timeline_path not in _queue:
			_queue.append(timeline_path)
		return
	if not ResourceLoader.exists(INTERLUDE_SCENE_PATH) \
			or not InterludeManager.is_eligible(timeline_path, WorldState.era_config):
		return
	WorldState.set_paused(true)
	var data: MapNodeData = (map.nodes[node_id] as MapNode).data if map.nodes.has(node_id) else null
	active_interlude = (load(INTERLUDE_SCENE_PATH) as PackedScene).instantiate()
	var title: String = data.liberation_title if data else WorldState.era_config.era_title
	active_interlude.call("setup", timeline_path, title, node_id)
	active_interlude.tree_exited.connect(_on_interlude_closed)
	_set_map_visible(false)
	map.get_tree().root.add_child(active_interlude)


func _on_interlude_closed() -> void:
	active_interlude = null
	_set_map_visible(true)
	if not _queue.is_empty() or _after_queue.is_valid():
		_play_queue()
		return
	map.on_encounter_resolved()


## Toca timelines em sequência e chama `then` ao final (clímax -> Derrota Falsa).
func play_sequence(timelines: Array[String], then: Callable) -> void:
	_queue.append_array(timelines)
	_after_queue = then
	if not is_busy():
		_play_queue()


func _play_queue() -> void:
	while not _queue.is_empty():
		var next: String = _queue.pop_front()
		if InterludeManager.is_eligible(next, WorldState.era_config):
			open_interlude(next, "")
			return
	var then: Callable = _after_queue
	_after_queue = Callable()
	if then.is_valid():
		then.call()


func _set_map_visible(value: bool) -> void:
	map.visible = value
	(map.get_node("%HUDLayer") as CanvasLayer).visible = value
	(map.get_node("%BackgroundLayer") as CanvasLayer).visible = value


## Nó aliado mais próximo para recuo após derrota.
func _nearest_player_node(from_position: Vector2) -> String:
	var best: String = ""
	var best_distance: float = INF
	for node_id: String in map.nodes:
		var distance: float = from_position.distance_to((map.nodes[node_id] as MapNode).position)
		if WorldState.get_node_faction(node_id) == "player" and distance < best_distance:
			best = node_id
			best_distance = distance
	return best


## Vitória: nenhum nó obrigatório nas mãos do inimigo e nenhum inimigo fixo fora de objetivos
## opcionais (errantes e guarnições de nós opcionais, como o Portão de Hanmen, não contam).
func check_victory() -> void:
	for node_id: String in map.nodes:
		var data: MapNodeData = (map.nodes[node_id] as MapNode).data
		if data.required_for_victory and WorldState.get_node_faction(node_id) == "enemy":
			return
	for token: SquadToken in map.tokens:
		var post: MapNode = map.nodes.get(token.squad.current_node_id)
		var optional_post: bool = not token.squad.is_patrol() and post != null and not post.data.required_for_victory
		if token.squad.faction == "enemy" and not token.squad.is_roaming and not optional_post:
			return
	if WorldState.has_flag("act_victory"):
		return
	WorldState.set_flag("act_victory")
	map.show_banner(WorldState.era_config.victory_text)
	var climax: Array[String] = WorldState.era_config.climax_timelines
	if not climax.is_empty():  # Clímax do ato e, em seguida, a Derrota Falsa.
		play_sequence(climax, func() -> void: FalseDefeat.trigger(map))


## Dispara o interlúdio de um nó na 1ª vez em que ele fica sob controle aliado.
func check_liberations() -> void:
	for node_id: String in map.nodes:
		var data: MapNodeData = (map.nodes[node_id] as MapNode).data
		var flag: String = "liberated_%s" % node_id
		if data.liberation_timeline.is_empty() or WorldState.has_flag(flag):
			continue
		if WorldState.get_node_faction(node_id) == "player":
			WorldState.set_flag(flag)
			EventBus.interlude_requested.emit(data.liberation_timeline, node_id)
			return
	for token: SquadToken in map.tokens:  # Primeira visita (ex.: vigília em Montségur).
		var node: MapNode = map.nodes.get(token.squad.current_node_id)
		if token.squad.faction != "player" or node == null or node.data.visit_timeline.is_empty() \
				or token.is_moving() or WorldState.has_flag("visited_%s" % node.data.node_id):
			continue
		WorldState.set_flag("visited_%s" % node.data.node_id)
		EventBus.interlude_requested.emit(node.data.visit_timeline, node.data.node_id)
		return

class_name EncounterDirector
extends Node
## Abre e fecha as camadas 2 (BattleArena) e 3 (InterludeRoom) sobre o mapa.
## Enquanto uma delas está ativa, o overworld fica pausado e oculto.

const BATTLE_SCENE: PackedScene = preload("res://core/combat/BattleArena.tscn")
const INTERLUDE_SCENE_PATH: String = "res://core/interlude/InterludeRoom.tscn"

var map: OverworldMap
var active_battle: BattleArena
var active_interlude: Node
var _ally_token: SquadToken
var _foe_token: SquadToken


func setup(p_map: OverworldMap) -> void:
	map = p_map
	EventBus.interlude_requested.connect(open_interlude)


func is_busy() -> bool:
	return active_battle != null or active_interlude != null


func start_battle(ally: SquadToken, foe: SquadToken) -> void:
	_ally_token = ally
	_foe_token = foe
	ally.path.clear()
	WorldState.set_paused(true)
	var context: Dictionary = {"node_id": foe.squad.current_node_id, "player_side": "attacker"}
	EventBus.battle_requested.emit(ally.squad, foe.squad, context)
	active_battle = BATTLE_SCENE.instantiate() as BattleArena
	active_battle.setup(ally.squad, foe.squad, context)
	active_battle.closed.connect(_on_battle_closed)
	_set_map_visible(false)
	map.get_tree().root.add_child(active_battle)


func _on_battle_closed(result: Dictionary) -> void:
	var effects: Dictionary = result.get("effects", {})
	BattleConsequences.apply(effects, _ally_token.squad)
	if bool(effects.get("player_won", false)):
		var node_id: String = _foe_token.squad.current_node_id
		map.remove_token(_foe_token)
		map.capture(node_id)
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


func open_interlude(timeline_path: String, node_id: String) -> void:
	if not ResourceLoader.exists(INTERLUDE_SCENE_PATH):
		return
	WorldState.set_paused(true)
	var data: MapNodeData = (map.nodes[node_id] as MapNode).data if map.nodes.has(node_id) else null
	active_interlude = (load(INTERLUDE_SCENE_PATH) as PackedScene).instantiate()
	active_interlude.call("setup", timeline_path, data.liberation_title if data else "", node_id)
	active_interlude.tree_exited.connect(_on_interlude_closed)
	_set_map_visible(false)
	map.get_tree().root.add_child(active_interlude)


func _on_interlude_closed() -> void:
	active_interlude = null
	_set_map_visible(true)
	map.on_encounter_resolved()


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

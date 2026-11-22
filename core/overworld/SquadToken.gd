class_name SquadToken
extends Node2D
## Token que marcha entre nós do mapa seguindo um caminho no grafo.

signal arrived(token: SquadToken, node_id: String)

const HIT_RADIUS: float = 26.0

var squad: SquadData
var path: Array[String] = []                 # Próximos nós a visitar
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
var _label: Label


func setup(p_squad: SquadData, start_position: Vector2) -> void:
	squad = p_squad
	position = start_position + _offset()
	_label = Label.new()
	_label.text = squad.display_name
	_label.size = Vector2(200, 22)
	_label.position = Vector2(-100, -54)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 5)
	add_child(_label)


func is_player() -> bool:
	return squad.faction == "player"


func is_moving() -> bool:
	return not path.is_empty()


func set_path(new_path: Array[String]) -> void:
	path = new_path
	queue_redraw()


## Avança na direção do próximo nó. `positions` = { node_id: Vector2 }.
func advance(delta: float, speed: float, positions: Dictionary) -> void:
	if path.is_empty():
		return
	var target: Vector2 = positions[path[0]] + _offset()
	var to_target: Vector2 = target - position
	var step: float = speed * delta
	if to_target.length() <= step:
		position = target
		var reached: String = path.pop_front()
		squad.current_node_id = reached
		arrived.emit(self, reached)
	else:
		position += to_target.normalized() * step


func teleport_to(node_id: String, node_position: Vector2) -> void:
	path.clear()
	squad.current_node_id = node_id
	position = node_position + _offset()


func contains_point(world_point: Vector2) -> bool:
	return world_point.distance_to(position) <= HIT_RADIUS


## Tokens ficam na diagonal do nó para não cobrir o ícone de tipo.
func _offset() -> Vector2:
	return Vector2(40, -38)


func _draw() -> void:
	if squad == null:
		return
	var era: EraConfig = WorldState.era_config
	var color: Color = era.color_for_faction(squad.faction) if era else Color.WHITE
	if selected:
		draw_arc(Vector2.ZERO, HIT_RADIUS, 0.0, TAU, 32, Color.WHITE, 3.0)
	draw_line(Vector2(-10, 18), Vector2(-10, -30), Color(0.15, 0.1, 0.05), 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -30), Vector2(18, -22), Vector2(-8, -12)]), color)
	draw_circle(Vector2(0, 10), 12.0, color.darkened(0.3))
	draw_arc(Vector2(0, 10), 12.0, 0.0, TAU, 24, Color.BLACK, 2.0)

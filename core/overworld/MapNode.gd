class_name MapNode
extends Node2D
## Nó capturável do mapa com indicador visual de facção e gatilho de evento.

const RADIUS: float = 17.0

var data: MapNodeData
var faction: String = "neutral"
var _label: Label


func setup(p_data: MapNodeData, p_faction: String) -> void:
	data = p_data
	position = data.map_position
	_label = Label.new()
	_label.text = data.display_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(180, 14)
	_label.position = Vector2(-90, RADIUS + 3) if data.label_side == "below" else Vector2(-90, -RADIUS - 17)
	_label.add_theme_font_size_override("font_size", 9)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)
	add_child(_label)
	set_faction(p_faction)


func set_faction(p_faction: String) -> void:
	faction = p_faction
	queue_redraw()


func contains_point(world_point: Vector2) -> bool:
	return world_point.distance_to(position) <= RADIUS + 4.0


func _draw() -> void:
	if data == null:
		return
	var era: EraConfig = WorldState.era_config
	var color: Color = era.color_for_faction(faction) if era else Color.GRAY
	draw_circle(Vector2.ZERO, RADIUS + 2.0, Color(0, 0, 0, 0.55))
	draw_circle(Vector2.ZERO, RADIUS, color.darkened(0.45))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, color, 2.0)
	match data.node_type:
		MapNodeData.NodeType.FORTRESS:
			draw_rect(Rect2(-7, -7, 14, 14), color)
			for x: float in [-7.0, -1.0, 5.0]:
				draw_rect(Rect2(x, -10, 2, 3), color)
		MapNodeData.NodeType.RESOURCE:
			draw_colored_polygon(PackedVector2Array([Vector2(0, -8), Vector2(8, 0), Vector2(0, 8), Vector2(-8, 0)]), color)
		MapNodeData.NodeType.PASS:
			draw_colored_polygon(PackedVector2Array([Vector2(-9, 6), Vector2(-2, -8), Vector2(2, -2), Vector2(5, -6), Vector2(10, 6)]), color)
		MapNodeData.NodeType.SERVER:
			draw_rect(Rect2(-6, -8, 12, 16), color, false, 2.0)
		_:
			draw_circle(Vector2.ZERO, 6.0, color)

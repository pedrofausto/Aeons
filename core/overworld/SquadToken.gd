class_name SquadToken
extends Node2D
## Token que marcha entre nós do mapa seguindo um caminho no grafo.

signal arrived(token: SquadToken, node_id: String)

const HIT_RADIUS: float = 16.0
const MOUNTAIN_FACTOR: float = 0.7  # Infantaria em montanha (SquadData.TERRAIN_FACTORS)

var squad: SquadData
var path: Array[String] = []                 # Próximos nós a visitar
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
var _label: Label
var _sprite: Sprite2D
var _walk_phase: float = 0.0


func setup(p_squad: SquadData, start_position: Vector2) -> void:
	squad = p_squad
	position = start_position + _offset()
	z_index = 20 if squad != null and squad.is_airborne() else 0
	var leader: UnitInstance = squad.get_leader() if squad != null else null
	if leader != null and leader.class_data != null and leader.class_data.sprite_texture != null:
		_sprite = Sprite2D.new()
		_sprite.texture = leader.class_data.sprite_texture
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var tex_h: float = maxf(_sprite.texture.get_size().y, 1.0)
		var sc: float = 26.0 / tex_h
		_sprite.scale = Vector2(sc, sc)
		_sprite.position = Vector2(0.0, -13.0 if z_index > 0 else -7.0)
		_sprite.flip_h = not is_player()
		add_child(_sprite)
	_label = Label.new()
	_label.text = squad.display_name
	_label.size = Vector2(160, 11)
	_label.position = Vector2(-80, -27) if position.y > 75.0 else Vector2(-80, 9)  # Perto do HUD: rótulo embaixo
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 7)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)
	add_child(_label)


func is_player() -> bool:
	return squad.faction == "player"


func is_moving() -> bool:
	return not path.is_empty()


func set_path(new_path: Array[String]) -> void:
	path = new_path
	queue_redraw()


## Avança na direção do próximo nó. `positions` = { node_id: Vector2 }.
## Velocidade efetiva: base x terreno x patrulha x classes (noite) x itens do jogador.
func march_speed(base: float, terrain: String = "plains") -> float:
	var speed: float = base * squad.march_factor(WorldState.time_of_day) * squad.terrain_factor(terrain)
	if squad.is_patrol():
		speed *= PatrolAI.SPEED_FACTOR
	if is_player():
		speed *= WorldState.item_march_multiplier()
	return speed


## Encontros noturnos ficam ocultos (emboscada) sem item que os revele.
func _process(delta: float) -> void:
	visible = not (squad != null and squad.roaming_until_day and not WorldState.reveals_night_encounters())
	if _sprite != null:
		var base_y: float = -13.0 if z_index > 0 else -7.0
		if is_moving() and not WorldState.is_paused:
			_walk_phase += delta * 14.0
			_sprite.position.y = base_y - absf(sin(_walk_phase)) * 2.5
			_sprite.rotation = sin(_walk_phase) * 0.07
		else:
			_walk_phase = 0.0
			_sprite.position.y = base_y
			_sprite.rotation = 0.0


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
		if _sprite != null and absf(to_target.x) > 0.5:
			_sprite.flip_h = to_target.x < 0.0
		position += to_target.normalized() * step


func teleport_to(node_id: String, node_position: Vector2) -> void:
	path.clear()
	squad.current_node_id = node_id
	position = node_position + _offset()


func contains_point(world_point: Vector2) -> bool:
	return world_point.distance_to(position) <= HIT_RADIUS


## Posição lógica no grafo (sem o deslocamento visual) — usada nas colisões.
func get_anchor() -> Vector2:
	return position - _offset()


## Tokens ficam na diagonal do nó para não cobrir o ícone; patrulhas, na diagonal oposta.
func _offset() -> Vector2:
	return Vector2(-30, -4) if squad != null and squad.is_patrol() else Vector2(20, -19)


func _draw() -> void:
	if squad == null:
		return
	var era: EraConfig = WorldState.era_config
	var color: Color = era.color_for_faction(squad.faction) if era else Color.WHITE
	if selected:
		draw_arc(Vector2.ZERO, HIT_RADIUS, 0.0, TAU, 24, Color.WHITE, 1.5)
	if _sprite != null:
		draw_circle(Vector2(0, 6), 7.0, Color(0, 0, 0, 0.45))
		draw_arc(Vector2(0, 6), 7.0, 0.0, TAU, 16, color, 1.5)
		return
	draw_line(Vector2(-5, 9), Vector2(-5, -15), Color(0.15, 0.1, 0.05), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -15), Vector2(9, -11), Vector2(-4, -6)]), color)
	draw_circle(Vector2(0, 5), 6.0, color.darkened(0.3))
	draw_arc(Vector2(0, 5), 6.0, 0.0, TAU, 16, Color.BLACK, 1.0)

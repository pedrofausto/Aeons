class_name UnitCardView
extends Node2D
## Placeholder visual de uma unidade na grade 3x2 (retângulo colorido + barras).
## Apenas reproduz números vindos do battle_log; nenhuma regra de combate aqui.

const SIZE: Vector2 = Vector2(60, 46)
const ARCHETYPE_COLORS: Array[Color] = [
	Color(0.55, 0.42, 0.3), Color(0.7, 0.3, 0.25), Color(0.35, 0.5, 0.35),
	Color(0.4, 0.35, 0.65), Color(0.85, 0.8, 0.6), Color(0.6, 0.45, 0.6), Color(0.9, 0.6, 0.2),
]

var unit: UnitInstance
var size: Vector2 = SIZE                      # Colossais (grid_slots 2) ocupam frente + trás
var faction_color: Color = Color.WHITE
var _hp: int = 0
var _morale: int = 0
var _flash: float = 0.0
var _label: Label


func setup(p_unit: UnitInstance, p_faction_color: Color) -> void:
	unit = p_unit
	if unit.class_data.grid_slots >= 2:
		size = Vector2(SIZE.x * 2.0 + 15.0, SIZE.y)
	faction_color = p_faction_color
	_hp = unit.hp
	_morale = unit.morale
	_label = Label.new()
	_label.position = Vector2(-size.x / 2.0 + 2, -size.y / 2.0 + 1)
	_label.size = Vector2(size.x - 4, 20)
	_label.add_theme_font_size_override("font_size", 6)
	_label.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.text = "%s%s\n%s Nv%d" % ["★ " if unit.is_leader else "", unit.unit_name,
		unit.class_data.display_name, unit.level]
	add_child(_label)
	queue_redraw()


func show_values(hp: int, morale: int) -> void:
	_hp = hp
	_morale = morale
	_flash = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.0)
		queue_redraw()


func _draw() -> void:
	if unit == null:
		return
	var rect := Rect2(-size / 2.0, size)
	var base: Color = ARCHETYPE_COLORS[unit.class_data.archetype]
	if unit.class_data.placeholder_color.a > 0.0:
		base = unit.class_data.placeholder_color
	if _hp <= 0:
		base = base.darkened(0.7)
	elif _morale <= 0:
		base = base.lerp(Color(0.6, 0.6, 0.7), 0.6)
	draw_rect(rect, base.lerp(Color.WHITE, _flash * 0.6))
	draw_rect(rect, faction_color, false, 1.5)
	var bar_w: float = size.x - 6.0
	var hp_ratio: float = clampf(float(_hp) / float(unit.get_max_hp()), 0.0, 1.0)
	var mor_ratio: float = clampf(float(_morale) / float(unit.get_max_morale()), 0.0, 1.0)
	var origin := Vector2(-size.x / 2.0 + 3, size.y / 2.0 - 12)
	draw_rect(Rect2(origin, Vector2(bar_w, 3)), Color(0.15, 0.05, 0.05))
	draw_rect(Rect2(origin, Vector2(bar_w * hp_ratio, 3)), Color(0.85, 0.2, 0.2))
	draw_rect(Rect2(origin + Vector2(0, 5), Vector2(bar_w, 3)), Color(0.05, 0.05, 0.15))
	draw_rect(Rect2(origin + Vector2(0, 5), Vector2(bar_w * mor_ratio, 3)), Color(0.3, 0.55, 0.95))
	if _hp <= 0:
		draw_line(rect.position, rect.end, Color(0.1, 0.1, 0.1), 1.5)

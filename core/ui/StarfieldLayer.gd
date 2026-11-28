class_name StarfieldLayer
extends Control
## Céu estrelado cobrindo toda a tela: estrelas esparsas até embaixo + 7 estrelas com pontas aparentes.

const NORMAL_STAR_COUNT := 125
const BRIGHT_STAR_COUNT := 7

var _stars: Array[Dictionary] = []
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_generate_stars()


func _generate_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7719
	for i: int in NORMAL_STAR_COUNT:
		_stars.append({
			"uv": Vector2(rng.randf_range(0.015, 0.985), rng.randf_range(0.02, 0.98)),
			"bright": false,
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.65, 1.55),
			"tint": Color(0.84, 0.90, 1.0) if i % 3 != 0 else Color(1.0, 0.95, 0.85),
			"size": 1.5 if i % 7 == 0 else 1.0,
		})
	var x_zones: Array[float] = [0.11, 0.24, 0.37, 0.50, 0.63, 0.76, 0.89]
	var y_zones: Array[float] = [0.18, 0.32, 0.14, 0.22, 0.16, 0.30, 0.20]
	for i: int in BRIGHT_STAR_COUNT:
		_stars.append({
			"uv": Vector2(x_zones[i] + rng.randf_range(-0.025, 0.025), y_zones[i] + rng.randf_range(-0.04, 0.04)),
			"bright": true,
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.85, 1.35),
			"tint": Color(0.95, 0.98, 1.0),
		})


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var area := Vector2(maxf(size.x, 640.0), maxf(size.y, 360.0))
	for s: Dictionary in _stars:
		var pos := (s["uv"] as Vector2) * area
		var wave := 0.5 + 0.5 * sin(_time * float(s["speed"]) + float(s["phase"]))
		var tint := s["tint"] as Color
		if bool(s["bright"]):
			var alpha := lerpf(0.80, 1.0, wave)
			var arm := 6.0 + wave * 1.5
			draw_line(pos - Vector2(arm, 0.0), pos + Vector2(arm, 0.0), Color(tint.r, tint.g, tint.b, alpha * 0.42), 1.0)
			draw_line(pos - Vector2(0.0, arm), pos + Vector2(0.0, arm), Color(tint.r, tint.g, tint.b, alpha * 0.42), 1.0)
			draw_line(pos - Vector2(arm * 0.5, 0.0), pos + Vector2(arm * 0.5, 0.0), Color(tint.r, tint.g, tint.b, alpha * 0.82), 1.0)
			draw_line(pos - Vector2(0.0, arm * 0.5), pos + Vector2(0.0, arm * 0.5), Color(tint.r, tint.g, tint.b, alpha * 0.82), 1.0)
			draw_circle(pos, 2.2, Color(tint.r, tint.g, tint.b, alpha * 0.30))
			draw_rect(Rect2(pos - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(1.0, 1.0, 1.0, alpha))
		else:
			var alpha := lerpf(0.16, 0.56, wave)
			var sz := float(s["size"])
			draw_rect(Rect2(pos, Vector2(sz, sz)), Color(tint.r, tint.g, tint.b, alpha))

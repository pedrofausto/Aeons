class_name StarfieldLayer
extends Control
## Céu estrelado discreto: estrelas esparsas piscando timidamente + 7 estrelas mais brilhantes.

const NORMAL_STAR_COUNT := 38
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
			"pos": Vector2(rng.randf_range(12.0, 628.0), rng.randf_range(8.0, 225.0)),
			"bright": false,
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.65, 1.45),
			"tint": Color(0.84, 0.89, 1.0) if i % 3 != 0 else Color(1.0, 0.94, 0.84),
		})
	var x_zones: Array[float] = [68.0, 148.0, 232.0, 320.0, 410.0, 496.0, 574.0]
	for i: int in BRIGHT_STAR_COUNT:
		_stars.append({
			"pos": Vector2(x_zones[i] + rng.randf_range(-18.0, 18.0), rng.randf_range(22.0, 132.0)),
			"bright": true,
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.8, 1.3),
			"tint": Color(0.92, 0.96, 1.0),
		})


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for s: Dictionary in _stars:
		var pos := s["pos"] as Vector2
		var wave := 0.5 + 0.5 * sin(_time * float(s["speed"]) + float(s["phase"]))
		var tint := s["tint"] as Color
		if bool(s["bright"]):
			var alpha := lerpf(0.60, 0.94, wave)
			var halo_a := alpha * 0.30
			draw_rect(Rect2(pos - Vector2(2.0, 0.0), Vector2(5.0, 1.0)), Color(tint.r, tint.g, tint.b, halo_a))
			draw_rect(Rect2(pos - Vector2(0.0, 2.0), Vector2(1.0, 5.0)), Color(tint.r, tint.g, tint.b, halo_a))
			draw_rect(Rect2(pos, Vector2(2.0, 2.0)), Color(tint.r, tint.g, tint.b, alpha))
		else:
			var alpha := lerpf(0.14, 0.48, wave)
			draw_rect(Rect2(pos, Vector2(1.0, 1.0)), Color(tint.r, tint.g, tint.b, alpha))

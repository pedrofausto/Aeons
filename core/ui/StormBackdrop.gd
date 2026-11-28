class_name StormBackdrop
extends Control
## Fundo animado de tempestade com 7 silhuetas reveladas por relâmpagos realistas.
## Primeiros 49s: apenas relâmpagos. Após 49s: exibe as 7 figuras em ordem 01->07 e some ao fim de cada flash.

signal flash_changed(intensity: float)

const SILHOUETTES_DIR := "res://core/ui/art/title_silhouettes"
const SILHOUETTE_PATHS: Array[String] = [
	"res://core/ui/art/title_silhouettes/01_athoth.jpg",
	"res://core/ui/art/title_silhouettes/02_eloaiou.jpg",
	"res://core/ui/art/title_silhouettes/03_astaphaios.jpg",
	"res://core/ui/art/title_silhouettes/04_yao.jpg",
	"res://core/ui/art/title_silhouettes/05_sabaoth.jpg",
	"res://core/ui/art/title_silhouettes/06_adonin.jpg",
	"res://core/ui/art/title_silhouettes/07_sabbede.jpg",
]
const SILHOUETTE_SHADER := preload("res://core/ui/shaders/storm_silhouette.gdshader")
const FIGURE_COUNT := 7

@export var calm_mode: bool = false
@export var silhouettes_delay_sec: float = 49.0

var _elapsed_sec: float = 0.0
var _flash: float = 0.0
var _celestial_glow: float = 0.0
var _next_flash_timer: float = 2.6
var _celestial_timer: float = 19.0
var _cloud_offset: float = 0.0
var _rain_drops: Array[Vector3] = []
var _bolts: Array[PackedVector2Array] = []
var _textures: Array[Texture2D] = []
var _current_idx: int = 0
var _silhouette_showing: bool = false
var _flash_tween: Tween
var _celestial_tween: Tween
var _sky_rect: ColorRect
var _clouds: TextureRect
var _figure_rect: TextureRect
var _flash_rect: ColorRect
var _dim_rect: ColorRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layers()
	_init_rain()
	_apply_flash_visuals()


func set_intro_dim(factor: float, duration: float = 1.2) -> void:
	var target_alpha := clampf(1.0 - factor, 0.0, 0.65)
	if _dim_rect == null:
		return
	var tw := create_tween()
	tw.tween_property(_dim_rect, "color:a", target_alpha, duration).set_trans(Tween.TRANS_SINE)


func _build_layers() -> void:
	_sky_rect = ColorRect.new()
	_sky_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sky_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_rect.color = Color(0.03, 0.04, 0.08, 1.0)
	add_child(_sky_rect)

	_clouds = TextureRect.new()
	_clouds.set_anchors_preset(Control.PRESET_FULL_RECT)
	_clouds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clouds.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_clouds.texture = _make_cloud_texture()
	_clouds.modulate = Color(0.55, 0.62, 0.78, 0.38)
	add_child(_clouds)

	_textures = _load_custom_silhouettes()
	if _textures.is_empty():
		for i: int in FIGURE_COUNT:
			_textures.append(_make_placeholder_silhouette(i))

	_figure_rect = TextureRect.new()
	_figure_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_figure_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_figure_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_figure_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_figure_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_figure_rect.texture = _textures[0]
	_figure_rect.visible = false
	var mat := ShaderMaterial.new()
	mat.shader = SILHOUETTE_SHADER
	mat.set_shader_parameter("flash_alpha", 0.38 if calm_mode else 0.90)
	_figure_rect.material = mat
	add_child(_figure_rect)

	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(0.75, 0.86, 1.0, 0.0)
	add_child(_flash_rect)

	_dim_rect = ColorRect.new()
	_dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim_rect.color = Color(0.02, 0.02, 0.04, 0.0)
	add_child(_dim_rect)


func _load_custom_silhouettes() -> Array[Texture2D]:
	var found: Array[Texture2D] = []
	for path: String in SILHOUETTE_PATHS:
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex != null:
				found.append(tex)
	return found


func _make_cloud_texture() -> Texture2D:
	var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	for y: int in 64:
		for x: int in 128:
			var n := sin(float(x) * 0.14) * cos(float(y) * 0.22) + sin(float(x + y) * 0.08) * 0.5
			var v := clampf((n + 1.2) * 0.35, 0.05, 0.85)
			img.set_pixel(x, y, Color(v * 0.35, v * 0.42, v * 0.60, v * 0.7))
	return ImageTexture.create_from_image(img)


func _make_placeholder_silhouette(idx: int) -> Texture2D:
	var img := Image.create(64, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.02, 0.03, 0.06, 1.0))
	var shoulder_w := 4 + (idx % 3) * 2
	for y: int in range(6, 34):
		var half := 2 if y < 12 else shoulder_w
		for x: int in range(32 - half, 32 + half + 1):
			img.set_pixel(x, y, Color(0.75, 0.82, 0.95, 1.0))
	return ImageTexture.create_from_image(img)


func _init_rain() -> void:
	for i: int in 45:
		_rain_drops.append(Vector3(randf_range(0.0, 640.0), randf_range(0.0, 360.0), randf_range(160.0, 250.0)))


func _process(delta: float) -> void:
	_elapsed_sec += delta
	_cloud_offset += delta * 6.0  # ~42s por ciclo
	_clouds.position.x = -fmod(_cloud_offset, 252.0)
	_next_flash_timer -= delta
	if _next_flash_timer <= 0.0:
		_trigger_lightning_cycle()
	_celestial_timer -= delta
	if _celestial_timer <= 0.0:
		_trigger_celestial_breath()
	for i: int in _rain_drops.size():
		var d: Vector3 = _rain_drops[i]
		d.x -= delta * d.z * 0.22
		d.y += delta * d.z
		if d.y > 360.0:
			d.y = -10.0
			d.x = randf_range(0.0, 700.0)
		_rain_drops[i] = d
	queue_redraw()


func _trigger_celestial_breath() -> void:
	_celestial_timer = 19.0
	if _celestial_tween != null and _celestial_tween.is_valid():
		_celestial_tween.kill()
	_celestial_tween = create_tween()
	_celestial_tween.tween_method(_set_celestial_glow, 0.0, 0.14, 3.0).set_trans(Tween.TRANS_SINE)
	_celestial_tween.tween_interval(1.0)
	_celestial_tween.tween_method(_set_celestial_glow, 0.14, 0.0, 3.0).set_trans(Tween.TRANS_SINE)


func _trigger_lightning_cycle() -> void:
	if not calm_mode and _elapsed_sec >= silhouettes_delay_sec and not _textures.is_empty():
		_figure_rect.texture = _textures[_current_idx]
		_current_idx = (_current_idx + 1) % _textures.size()
		_silhouette_showing = true
		_figure_rect.visible = true
	else:
		_silhouette_showing = false
		_figure_rect.visible = false
	var reduced := calm_mode or bool(SaveSystem.settings.get("reduce_flashes", false))
	_next_flash_timer = randf_range(12.0, 20.0) if reduced else randf_range(8.5, 15.5)
	_bolts.clear()
	if not reduced:
		var bx := randf_range(90.0, 550.0)
		var pts := PackedVector2Array([Vector2(bx, 0.0)])
		for step: int in 6:
			bx += randf_range(-24.0, 24.0)
			pts.append(Vector2(bx, float(step + 1) * 32.0))
		_bolts.append(pts)
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	if reduced:
		_flash_tween.tween_method(_set_flash, 0.0, 0.28, 0.35).set_trans(Tween.TRANS_SINE)
		_flash_tween.tween_method(_set_flash, 0.28, 0.0, 1.1).set_trans(Tween.TRANS_SINE)
	else:
		_flash_tween.tween_method(_set_flash, 0.0, 0.85, 0.06)
		_flash_tween.tween_method(_set_flash, 0.85, 0.18, 0.08)
		_flash_tween.tween_method(_set_flash, 0.18, 1.0, 0.12)
		_flash_tween.tween_method(_set_flash, 1.0, 0.0, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_callback(_hide_silhouette)


func _hide_silhouette() -> void:
	_silhouette_showing = false
	_figure_rect.visible = false


func _set_flash(v: float) -> void:
	_flash = v
	_apply_flash_visuals()


func _set_celestial_glow(v: float) -> void:
	_celestial_glow = v
	_apply_flash_visuals()


func _apply_flash_visuals() -> void:
	var cap := 0.18 if (calm_mode or bool(SaveSystem.settings.get("reduce_flashes", false))) else 0.32
	_flash_rect.color.a = _flash * cap
	var sky_t := clampf(_flash + _celestial_glow * 0.5, 0.0, 1.0)
	_sky_rect.color = Color(0.03, 0.04, 0.08).lerp(Color(0.16, 0.22, 0.36), sky_t)
	if _silhouette_showing and _flash > 0.005:
		_figure_rect.visible = true
		var mat := _figure_rect.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("flash_amount", _flash)
	else:
		_figure_rect.visible = false
	flash_changed.emit(_flash)


func _draw() -> void:
	for d: Vector3 in _rain_drops:
		var p := Vector2(d.x, d.y)
		draw_line(p, p + Vector2(-4.0, 14.0), Color(0.65, 0.78, 0.95, 0.14 + _flash * 0.15), 1.0)
	if _flash > 0.20:
		for bolt: PackedVector2Array in _bolts:
			draw_polyline(bolt, Color(0.85, 0.94, 1.0, _flash * 0.85), 1.8)

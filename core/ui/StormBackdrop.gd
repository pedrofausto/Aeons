class_name StormBackdrop
extends Control
## Fundo animado de tempestade com as 7 silhuetas translúcidas reveladas por clarões.
## Lê até 7 imagens em res://core/ui/art/title_silhouettes/ e alterna entre elas nos clarões.

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

var _flash: float = 0.0
var _next_flash_timer: float = 0.9
var _cloud_offset: float = 0.0
var _rain_drops: Array[Vector3] = []
var _bolts: Array[PackedVector2Array] = []
var _textures: Array[Texture2D] = []
var _current_idx: int = 0
var _sky_rect: ColorRect
var _clouds: TextureRect
var _figure_rect: TextureRect
var _flash_rect: ColorRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layers()
	_init_rain()
	_apply_flash_visuals()


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
	_clouds.modulate = Color(0.55, 0.62, 0.78, 0.42)
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
	var mat := ShaderMaterial.new()
	mat.shader = SILHOUETTE_SHADER
	mat.set_shader_parameter("base_alpha", 0.06 if calm_mode else 0.12)
	mat.set_shader_parameter("flash_alpha", 0.42 if calm_mode else 0.92)
	_figure_rect.material = mat
	add_child(_figure_rect)

	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(0.75, 0.86, 1.0, 0.0)
	add_child(_flash_rect)


func _load_custom_silhouettes() -> Array[Texture2D]:
	var found: Array[Texture2D] = []
	for path: String in SILHOUETTE_PATHS:
		if ResourceLoader.exists(path):
			var tex := load(path) as Texture2D
			if tex != null:
				found.append(tex)
	if not found.is_empty():
		return found
	var dir := DirAccess.open(SILHOUETTES_DIR)
	if dir == null:
		return found
	var files: Array[String] = []
	for raw_name: String in dir.get_files():
		var fname := raw_name.trim_suffix(".import").trim_suffix(".remap")
		if fname.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"] and fname not in files:
			files.append(fname)
	files.sort()
	for fname: String in files:
		var tex := load(SILHOUETTES_DIR.path_join(fname)) as Texture2D
		if tex != null:
			found.append(tex)
		if found.size() >= FIGURE_COUNT:
			break
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
	for i: int in 75:
		_rain_drops.append(Vector3(randf_range(0.0, 640.0), randf_range(0.0, 360.0), randf_range(210.0, 340.0)))


func _process(delta: float) -> void:
	_cloud_offset += delta * 8.0
	_clouds.position.x = -fmod(_cloud_offset, 48.0)
	_next_flash_timer -= delta
	if _next_flash_timer <= 0.0:
		_trigger_flash()
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 2.1)
		_apply_flash_visuals()
	for i: int in _rain_drops.size():
		var d: Vector3 = _rain_drops[i]
		d.x -= delta * d.z * 0.25
		d.y += delta * d.z
		if d.y > 360.0:
			d.y = -10.0
			d.x = randf_range(0.0, 700.0)
		_rain_drops[i] = d
	queue_redraw()


func _trigger_flash() -> void:
	if not _textures.is_empty():
		_current_idx = (_current_idx + 1) % _textures.size()
		_figure_rect.texture = _textures[_current_idx]
	var reduced := bool(SaveSystem.settings.get("reduce_flashes", false))
	_flash = 0.28 if (calm_mode or reduced) else randf_range(0.78, 1.0)
	_next_flash_timer = randf_range(3.2, 5.8) if calm_mode else randf_range(1.9, 4.0)
	_bolts.clear()
	if not calm_mode and not reduced:
		var bx := randf_range(80.0, 560.0)
		var pts := PackedVector2Array([Vector2(bx, 0.0)])
		for step: int in 6:
			bx += randf_range(-24.0, 24.0)
			pts.append(Vector2(bx, float(step + 1) * 32.0))
		_bolts.append(pts)
	_apply_flash_visuals()


func _apply_flash_visuals() -> void:
	var cap := 0.20 if (calm_mode or bool(SaveSystem.settings.get("reduce_flashes", false))) else 0.36
	_flash_rect.color.a = _flash * cap
	_sky_rect.color = Color(0.03, 0.04, 0.08).lerp(Color(0.16, 0.22, 0.36), _flash)
	var mat := _figure_rect.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("flash_amount", _flash)
	flash_changed.emit(_flash)


func _draw() -> void:
	for d: Vector3 in _rain_drops:
		var p := Vector2(d.x, d.y)
		draw_line(p, p + Vector2(-4.0, 14.0), Color(0.65, 0.78, 0.95, 0.16 + _flash * 0.15), 1.0)
	if _flash > 0.15:
		for bolt: PackedVector2Array in _bolts:
			draw_polyline(bolt, Color(0.85, 0.94, 1.0, _flash * 0.85), 1.8)

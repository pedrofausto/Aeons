class_name BattleUnit3D
extends Node3D
## Combatente 2D em billboard sobre o piso plano y = 0 da Arena 2.5D.
## Suporta folhas 4x4 (0=Idle, 1=Dash, 2=Attack, 3=Hit), sombra e animação 2.5D.

const ARCHETYPE_COLORS: Array[Color] = [
	Color(0.55, 0.42, 0.3), Color(0.7, 0.3, 0.25), Color(0.35, 0.5, 0.35),
	Color(0.4, 0.35, 0.65), Color(0.85, 0.8, 0.6), Color(0.6, 0.45, 0.6), Color(0.9, 0.6, 0.2),
]

var unit: UnitInstance
var home_pos: Vector3 = Vector3.ZERO
var active_turn: bool = false:
	set(value):
		active_turn = value
		_refresh_ring()
var target_highlighted: bool = false:
	set(value):
		target_highlighted = value
		_refresh_ring()

var _sprite: Sprite3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _has_sheet: bool = false
var _sheet_cols: int = 4
var _sheet_rows: int = 4
var _anim_row: int = 0
var _anim_col: int = 0
var _anim_timer: float = 0.0
var _anim_one_shot: bool = false
var _base_modulate: Color = Color.WHITE


func setup(p_unit: UnitInstance, p_pos: Vector3, p_flip_h: bool) -> void:
	unit = p_unit
	home_pos = p_pos
	position = p_pos
	_build_shadow()
	_build_ring()
	_build_sprite(p_flip_h)
	sync_vitals(unit.hp, unit.morale)


func _build_shadow() -> void:
	var shadow := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.95, 0.55)
	shadow.mesh = quad
	shadow.rotation_degrees.x = -90.0
	shadow.position = Vector3(0.0, 0.015, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.0, 0.0, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = mat
	add_child(shadow)


func _build_ring() -> void:
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.44
	torus.outer_radius = 0.54
	torus.rings = 16
	torus.ring_segments = 6
	_ring.mesh = torus
	_ring.scale = Vector3(1.0, 0.15, 1.0)
	_ring.position = Vector3(0.0, 0.03, 0.0)
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring.material_override = _ring_mat
	_ring.visible = false
	add_child(_ring)


func _build_sprite(p_flip_h: bool) -> void:
	_sprite = Sprite3D.new()
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_sprite.shaded = false
	_sprite.flip_h = p_flip_h
	var tex: Texture2D = unit.class_data.anim_sheet_4x4
	if tex != null:
		_has_sheet = true; _sheet_cols = 4; _sheet_rows = 4
	elif unit.class_data.class_id in ["fubing", "nubing_crossbow"]:
		var p := "res://eras/act_01_tianxu/art/battle_25d/sprites/%s_sheet.png" % ("nubing" if unit.class_data.class_id == "nubing_crossbow" else "fubing")
		if ResourceLoader.exists(p):
			tex = load(p) as Texture2D; _has_sheet = true; _sheet_cols = 3; _sheet_rows = 1
	if tex == null:
		tex = unit.class_data.sprite_texture if unit.class_data.sprite_texture != null else _make_fallback_tex(ARCHETYPE_COLORS[unit.class_data.archetype])
	_sprite.texture = tex
	var frame_h: float = tex.get_size().y / float(_sheet_rows) if _has_sheet else tex.get_size().y
	if _has_sheet:
		_sprite.hframes = _sheet_cols; _sprite.vframes = _sheet_rows; _sprite.frame = 0
	var target_h: float = 1.65 if unit.class_data.grid_slots >= 2 else 1.25
	_sprite.pixel_size = target_h / maxf(frame_h, 1.0)
	_sprite.position = Vector3(0.0, target_h * 0.5, 0.0)
	add_child(_sprite)


func _make_fallback_tex(col: Color) -> Texture2D:
	var img := Image.create(16, 28, false, Image.FORMAT_RGBA8)
	img.fill(col)
	for x: int in 16:
		img.set_pixel(x, 0, Color.BLACK); img.set_pixel(x, 27, Color.BLACK)
	for y: int in 28:
		img.set_pixel(0, y, Color.BLACK); img.set_pixel(15, y, Color.BLACK)
	return ImageTexture.create_from_image(img)

func _refresh_ring() -> void:
	if _ring == null or _ring_mat == null:
		return
	if active_turn:
		_ring_mat.albedo_color = Color(1.0, 0.85, 0.25); _ring.visible = true
	elif target_highlighted:
		_ring_mat.albedo_color = Color(1.0, 0.3, 0.25); _ring.visible = true
	else:
		_ring.visible = false

func play_anim(row: int, one_shot: bool = false) -> void:
	if not _has_sheet or _sprite == null:
		return
	if _sheet_rows == 1:
		_anim_row = 0
		_anim_col = 2 if row == 2 else (1 if row >= 1 else 0)
		_anim_one_shot = one_shot
		_sprite.frame = _anim_col
		return
	_anim_row = clampi(row, 0, 3)
	_anim_col = 0; _anim_timer = 0.0; _anim_one_shot = one_shot
	_sprite.frame = _anim_row * 4


func sync_vitals(hp: int, morale: int) -> void:
	if _sprite == null:
		return
	if hp <= 0:
		_base_modulate = Color(0.32, 0.32, 0.36, 0.55)
		_sprite.rotation_degrees.z = 78.0
	elif morale <= 0:
		_base_modulate = Color(0.65, 0.68, 0.88, 0.9)
		_sprite.rotation_degrees.z = 0.0
	else:
		_base_modulate = Color.WHITE
		_sprite.rotation_degrees.z = 0.0
	_sprite.modulate = _base_modulate


func play_attack_toward(target_pos: Vector3, is_melee: bool, fx_color: Color, duration: float) -> void:
	if duration <= 0.0 or not is_inside_tree():
		return
	var dir: Vector3 = target_pos - home_pos
	dir.y = 0.0
	var dist: float = maxf(dir.length(), 0.01)
	var stop_pos: Vector3 = target_pos - (dir / dist) * minf(0.85, dist * 0.5)
	stop_pos.y = 0.0
	if is_melee:
		play_anim(1, false)
		var tw := create_tween()
		tw.tween_property(self, "position", stop_pos, duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw.finished
		play_anim(2, true)
		_spawn_slash_fx(target_pos + Vector3(0.0, 0.55, 0.0), fx_color, duration * 0.35)
		await get_tree().create_timer(duration * 0.3).timeout
		play_anim(1, false)
		var tw_back := create_tween()
		tw_back.tween_property(self, "position", home_pos, duration * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw_back.finished
		play_anim(0, false)
	else:
		play_anim(2, true)
		_spawn_projectile_fx(home_pos + Vector3(0.0, 0.7, 0.0), target_pos + Vector3(0.0, 0.55, 0.0), fx_color, duration * 0.6)
		await get_tree().create_timer(duration * 0.65).timeout


func play_hit(knock_dir: Vector3, duration: float) -> void:
	if duration <= 0.0 or not is_inside_tree():
		return
	play_anim(3, true)
	if _sprite != null:
		_sprite.modulate = Color(1.8, 1.5, 1.4, 1.0)
	var offset: Vector3 = knock_dir.normalized() * 0.22
	offset.y = 0.0
	var tw := create_tween()
	tw.tween_property(self, "position", home_pos + offset, duration * 0.25)
	tw.tween_property(self, "position", home_pos, duration * 0.35)
	await tw.finished
	if _sprite != null:
		_sprite.modulate = _base_modulate


func _spawn_slash_fx(at_pos: Vector3, fx_color: Color, life: float) -> void:
	if get_parent() == null:
		return
	var fx := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.14, 0.14)
	fx.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = fx_color; mat.emission_enabled = true; mat.emission = fx_color; mat.emission_energy_multiplier = 2.0
	fx.material_override = mat
	get_parent().add_child(fx)
	fx.position = at_pos
	fx.rotation_degrees = Vector3(0.0, randf_range(-35.0, 35.0), randf_range(-35.0, 35.0))
	var tw := fx.create_tween()
	tw.tween_property(fx, "scale", Vector3(1.4, 0.2, 1.4), life)
	tw.finished.connect(fx.queue_free)


func _spawn_projectile_fx(from_pos: Vector3, to_pos: Vector3, fx_color: Color, life: float) -> void:
	if get_parent() == null:
		return
	var orb := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.14
	sphere.height = 0.28
	orb.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = fx_color; mat.emission_enabled = true; mat.emission = fx_color; mat.emission_energy_multiplier = 2.2
	orb.material_override = mat
	get_parent().add_child(orb)
	orb.position = from_pos
	var tw := orb.create_tween()
	tw.tween_method(func(t: float) -> void:
		if is_instance_valid(orb):
			orb.position = from_pos.lerp(to_pos, t) + Vector3(0.0, sin(t * PI) * 0.75, 0.0),
		0.0, 1.0, life)
	tw.finished.connect(orb.queue_free)


func _process(delta: float) -> void:
	if _has_sheet and _sheet_rows > 1 and _sprite != null and unit != null and unit.is_alive():
		_anim_timer += delta
		var rate: float = 0.1 if _anim_one_shot else 0.22
		if _anim_timer >= rate:
			_anim_timer = 0.0
			_anim_col += 1
			if _anim_col >= 4:
				_anim_col = 0
				if _anim_one_shot:
					_anim_one_shot = false
					_anim_row = 0
			_sprite.frame = _anim_row * 4 + _anim_col

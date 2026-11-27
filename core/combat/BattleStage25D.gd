class_name BattleStage25D
extends Node3D
## Palco 2.5D plano rotacionável (estilo Ogre Battle HD-2D):
## piso central 100% plano (y = 0) sem obstáculos, 4 lanternas de canto e câmera orbital Q/E.

const ALLY_ROW_X: Array[float] = [1.45, 2.85]
const ENEMY_ROW_X: Array[float] = [-1.45, -2.85]
const COLUMN_Z: Array[float] = [-1.55, 0.0, 1.55]
const ANGLE_STEP_DEG: float = 90.0

var _pivot: Node3D
var _camera: Camera3D
var _units_root: Node3D
var _units: Dictionary = {}
var _yaw_deg: float = 45.0
var _shake_time: float = 0.0
var _shake_intensity: float = 0.0


func _ready() -> void:
	_build_environment()
	_build_flat_platform()
	_build_camera()
	_units_root = Node3D.new()
	add_child(_units_root)


func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.52, 0.58)
	e.ambient_light_energy = 0.85
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, 35.0, 0.0)
	sun.light_energy = 0.9
	add_child(sun)


func _build_flat_platform() -> void:
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(9.2, 0.24, 6.2)
	floor_mesh.mesh = box
	floor_mesh.position = Vector3(0.0, -0.12, 0.0)
	var mat := StandardMaterial3D.new()
	var floor_tex_path := "res://eras/act_01_tianxu/art/battle_25d/props/stone_floor_tiles.png"
	var floor_norm_path := "res://eras/act_01_tianxu/art/battle_25d/props/stone_floor_tiles_n.png"
	if ResourceLoader.exists(floor_tex_path):
		mat.albedo_texture = load(floor_tex_path) as Texture2D
		if ResourceLoader.exists(floor_norm_path):
			mat.normal_enabled = true
			mat.normal_texture = load(floor_norm_path) as Texture2D
		mat.uv1_scale = Vector3(3.0, 2.0, 1.0)
	else:
		mat.albedo_texture = _make_stone_grid_texture()
		mat.uv1_scale = Vector3(6.0, 4.0, 1.0)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	floor_mesh.material_override = mat
	add_child(floor_mesh)
	var trim := MeshInstance3D.new()
	var trim_box := BoxMesh.new()
	trim_box.size = Vector3(9.6, 0.16, 6.6)
	trim.mesh = trim_box
	trim.position = Vector3(0.0, -0.16, 0.0)
	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = Color(0.2, 0.18, 0.16)
	trim.material_override = trim_mat
	add_child(trim)
	for corner: Vector3 in [Vector3(4.55, 0.0, 3.05), Vector3(-4.55, 0.0, 3.05),
			Vector3(4.55, 0.0, -3.05), Vector3(-4.55, 0.0, -3.05)]:
		_spawn_corner_lantern(corner)


func _spawn_corner_lantern(pos: Vector3) -> void:
	var post := MeshInstance3D.new()
	var post_box := BoxMesh.new()
	post_box.size = Vector3(0.18, 0.9, 0.18)
	post.mesh = post_box
	post.position = pos + Vector3(0.0, 0.45, 0.0)
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.24, 0.19, 0.15)
	post.material_override = post_mat
	add_child(post)
	var lamp := MeshInstance3D.new()
	var lamp_box := BoxMesh.new()
	lamp_box.size = Vector3(0.28, 0.28, 0.28)
	lamp.mesh = lamp_box
	lamp.position = pos + Vector3(0.0, 1.02, 0.0)
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(1.0, 0.78, 0.35)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.65, 0.2)
	lamp_mat.emission_energy_multiplier = 1.6
	lamp.material_override = lamp_mat
	add_child(lamp)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0.0, 1.15, 0.0)
	light.light_color = Color(1.0, 0.72, 0.38)
	light.light_energy = 1.1
	light.omni_range = 4.5
	add_child(light)


func _make_stone_grid_texture() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	for y: int in 32:
		for x: int in 32:
			var edge: bool = x == 0 or y == 0 or x == 16 or y == 16
			var shade: float = 0.22 if edge else (0.35 if ((x / 16 + y / 16) % 2 == 0) else 0.32)
			var noise: float = float((x * 7 + y * 13) % 5) * 0.008
			img.set_pixel(x, y, Color(shade + noise + 0.03, shade + noise, shade + noise - 0.02))
	return ImageTexture.create_from_image(img)


func _build_camera() -> void:
	_pivot = Node3D.new()
	_pivot.rotation_degrees = Vector3(-34.0, _yaw_deg, 0.0)
	add_child(_pivot)
	_camera = Camera3D.new()
	_camera.fov = 34.0
	_camera.position = Vector3(0.0, 0.0, 12.2)
	_pivot.add_child(_camera)


func rotate_camera(step_dir: int) -> void:
	_yaw_deg += float(step_dir) * ANGLE_STEP_DEG
	if _pivot == null or not is_inside_tree():
		return
	var tw := create_tween()
	tw.tween_property(_pivot, "rotation_degrees:y", _yaw_deg, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func build_squads(ally_squad: SquadData, enemy_squad: SquadData, player_side: String) -> void:
	for child: Node in _units_root.get_children():
		child.queue_free()
	_units.clear()
	var foe_side: String = "defender" if player_side == "attacker" else "attacker"
	_spawn_squad(ally_squad, player_side, true)
	_spawn_squad(enemy_squad, foe_side, false)


func _spawn_squad(squad: SquadData, side: String, is_ally: bool) -> void:
	if squad == null:
		return
	var rows: Array[float] = ALLY_ROW_X if is_ally else ENEMY_ROW_X
	for i: int in squad.units.size():
		var unit: UnitInstance = squad.units[i]
		unit.ensure_vitals()
		var x: float = (rows[0] + rows[1]) * 0.5 if unit.class_data.grid_slots >= 2 else rows[unit.get_row()]
		var z: float = COLUMN_Z[clampi(unit.get_column(), 0, 2)]
		var view := BattleUnit3D.new()
		_units_root.add_child(view)
		view.setup(unit, Vector3(x, 0.0, z), is_ally)
		_units["%s:%d" % [side, i]] = view


func get_unit_view(side: String, index: int) -> BattleUnit3D:
	return _units.get("%s:%d" % [side, index]) as BattleUnit3D


func sync_all() -> void:
	for key: Variant in _units:
		var view := _units[key] as BattleUnit3D
		if view != null and view.unit != null:
			view.sync_vitals(view.unit.hp, view.unit.morale)


func set_highlights(active_key: String, foe_side: String, mark_enemies: bool) -> void:
	for key: Variant in _units:
		var view := _units[key] as BattleUnit3D
		if view == null:
			continue
		view.active_turn = String(key) == active_key
		view.target_highlighted = mark_enemies and String(key).begins_with(foe_side + ":") and view.unit.is_alive()


func pick_enemy_at_viewport_pos(vp_pos: Vector2, foe_side: String) -> int:
	if _camera == null:
		return -1
	var best_idx: int = -1
	var best_dist: float = 34.0
	for key: Variant in _units:
		var skey: String = String(key)
		if not skey.begins_with(foe_side + ":"):
			continue
		var view := _units[key] as BattleUnit3D
		if view == null or not view.unit.is_alive():
			continue
		var screen_pt: Vector2 = _camera.unproject_position(view.global_position + Vector3(0.0, 0.55, 0.0))
		var d: float = screen_pt.distance_to(vp_pos)
		if d < best_dist:
			best_dist = d
			best_idx = int(skey.get_slice(":", 1))
	return best_idx


func trigger_hitstop_and_shake(duration: float, intensity: float) -> void:
	if duration <= 0.0:
		return
	_shake_time = maxf(_shake_time, duration)
	_shake_intensity = maxf(_shake_intensity, intensity)


func play_action_fx(actor_u: UnitInstance, event: Dictionary, step_seconds: float) -> void:
	var a_view := get_unit_view(String(event["actor_side"]), int(event["actor_index"]))
	var t_view := get_unit_view(String(event["target_side"]), int(event["target_index"]))
	if step_seconds > 0.0 and a_view != null and t_view != null and a_view != t_view:
		var is_melee: bool = actor_u.get_row() == 0 and int(event["heal"]) == 0
		var fx_col := Color(0.4, 0.9, 0.4) if int(event["heal"]) > 0 else Color(1.0, 0.78, 0.35)
		await a_view.play_attack_toward(t_view.home_pos, is_melee, fx_col, step_seconds * 0.9)
		if int(event["damage"]) > 0:
			trigger_hitstop_and_shake(0.12, 0.09)
			await get_tree().create_timer(0.045).timeout
			await t_view.play_hit(t_view.home_pos - a_view.home_pos, step_seconds * 0.45)
	if t_view != null:
		t_view.sync_vitals(int(event["target_hp"]), int(event["target_morale"]))


func _process(delta: float) -> void:
	if _camera == null:
		return
	if _shake_time > 0.0:
		_shake_time = maxf(0.0, _shake_time - delta)
		_camera.h_offset = randf_range(-_shake_intensity, _shake_intensity)
		_camera.v_offset = randf_range(-_shake_intensity, _shake_intensity)
		if _shake_time <= 0.0:
			_camera.h_offset = 0.0
			_camera.v_offset = 0.0
			_shake_intensity = 0.0

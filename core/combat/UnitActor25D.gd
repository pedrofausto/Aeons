extends Node2D
class_name UnitActor25D

## Visual 2.5D actor bound to a canonical UnitInstance (slot 0..2 front, 3..5 back).

@export var sprite_texture: Texture2D
@export var normal_texture: Texture2D
@export var frame_count: int = 3

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Polygon2D = $Shadow
@onready var hp_bar: ColorRect = $Bars/HPFill
@onready var morale_bar: ColorRect = $Bars/MoraleFill

var unit_slot: int = 0
var is_enemy: bool = false
var _base_pos: Vector2 = Vector2.ZERO


func setup(slot_index: int, enemy_side: bool, depth_scale: float, diffuse: Texture2D, normal: Texture2D) -> void:
	unit_slot = slot_index
	is_enemy = enemy_side
	_base_pos = position
	scale = Vector2(depth_scale, depth_scale)

	var canvas_tex := CanvasTexture.new()
	canvas_tex.diffuse_texture = diffuse
	canvas_tex.normal_texture = normal
	sprite.texture = canvas_tex
	sprite.hframes = frame_count
	sprite.frame = 0
	sprite.flip_h = enemy_side
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func update_bars(hp_ratio: float, morale_ratio: float) -> void:
	hp_bar.scale.x = clampf(hp_ratio, 0.0, 1.0)
	morale_bar.scale.x = clampf(morale_ratio, 0.0, 1.0)
	if sprite.material is ShaderMaterial:
		var mat := sprite.material as ShaderMaterial
		mat.set_shader_parameter("morale_dim", 0.65 if morale_ratio <= 0.0 else 0.0)


func play_attack_sequence(target_global_pos: Vector2, is_melee: bool) -> void:
	sprite.frame = 1
	var tw := create_tween()
	if is_melee:
		var lunge_pos := _base_pos.lerp(to_local(target_global_pos) + _base_pos, 0.55)
		tw.tween_property(self, "position", lunge_pos, 0.14).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void: sprite.frame = 2)
	tw.tween_interval(0.18)
	if is_melee:
		tw.tween_property(self, "position", _base_pos, 0.14).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void: sprite.frame = 0)


func play_hit_flash() -> void:
	if not (sprite.material is ShaderMaterial):
		return
	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("flash_amount", 1.0)
	var tw := create_tween()
	tw.tween_property(mat, "shader_parameter/flash_amount", 0.0, 0.14)

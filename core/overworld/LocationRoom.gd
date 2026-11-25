class_name LocationRoom
extends Node2D
## Vista de ambiente ao entrar em uma cidade/local aliado: exibe o fundo próprio,
## os sprites do esquadrão presente e o guardião/NPC local, permitindo descansar.

signal closed

var node_data: MapNodeData
var squad: SquadData

@onready var _backdrop: TextureRect = %Backdrop
@onready var _characters: Node2D = %Characters
@onready var _header: Label = %Header
@onready var _info: Label = %InfoLabel
@onready var _rest_btn: Button = %RestButton
@onready var _close_btn: Button = %CloseButton
@onready var _ui_root: Control = %UIRoot


func setup(p_data: MapNodeData, p_squad: SquadData) -> void:
	node_data = p_data
	squad = p_squad


func _ready() -> void:
	var era: EraConfig = WorldState.era_config
	if era:
		_ui_root.theme = era.ui_theme
	if node_data != null:
		_header.text = node_data.display_name
		_backdrop.texture = node_data.location_backdrop if node_data.location_backdrop != null else (era.battle_backdrop if era else null)
		_info.text = "%s  |  Renda: +%d %s/dia" % [node_data.terrain.capitalize(), node_data.gold_per_tick, era.resource_label if era else "Ouro"]
		_spawn_characters()
	_rest_btn.pressed.connect(_on_rest)
	_close_btn.pressed.connect(func() -> void: closed.emit())
	if OS.is_debug_build() and node_data != null:
		print("TEST_PASS|location_room_boot|%s" % node_data.node_id)


func _spawn_characters() -> void:
	if squad != null:
		var idx: int = 0
		for unit: UnitInstance in squad.get_living_units():
			if unit.class_data.sprite_texture == null:
				continue
			_add_actor_sprite(unit.class_data.sprite_texture, Vector2(120.0 + idx * 42.0, 238.0), false)
			idx += 1
	if node_data.location_npc_sprite != null:
		_add_actor_sprite(node_data.location_npc_sprite, Vector2(490.0, 238.0), true)


func _add_actor_sprite(tex: Texture2D, pos: Vector2, flip_h: bool) -> void:
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.flip_h = flip_h
	var sc: float = 96.0 / maxf(tex.get_size().y, 1.0)
	spr.scale = Vector2(sc, sc)
	spr.position = pos
	_characters.add_child(spr)


func _on_rest() -> void:
	if squad != null:
		squad.rest(15)
		squad.restore_morale()
	_rest_btn.disabled = true
	_info.text = "Esquadrão descansou (+15% HP, Moral restaurada)."

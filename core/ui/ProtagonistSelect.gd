class_name ProtagonistSelect
extends Control
## Tela de escolha de protagonista (3 silhuetas sem rótulo, nome, cor dos olhos e postura).

const EYE_COLORS: Array[Dictionary] = [
	{"name": "Âmbar", "color": Color(0.85, 0.58, 0.18)},
	{"name": "Jade", "color": Color(0.24, 0.72, 0.50)},
	{"name": "Aço", "color": Color(0.62, 0.70, 0.78)},
	{"name": "Obsidiana", "color": Color(0.18, 0.16, 0.22)},
	{"name": "Safira", "color": Color(0.26, 0.52, 0.88)},
	{"name": "Carmesim", "color": Color(0.76, 0.22, 0.24)},
]

const VICTORY_POSES: Array[String] = [
	"Espada Cravada em Silêncio",
	"Mão Erguida ao Céu",
	"Olhar Sobre o Ombro",
	"Reverência Serena",
]

var _selected_silhouette: int = 0
var _selected_eye_idx: int = 0
var _silhouette_btns: Array[Button] = []
var _eye_btns: Array[Button] = []

@onready var _name_input: LineEdit = %NameInput
@onready var _pose_select: OptionButton = %PoseSelect
@onready var _eye_label: Label = %EyeLabel
@onready var _silhouettes_box: HBoxContainer = %SilhouettesBox
@onready var _eyes_box: HBoxContainer = %EyesBox


func _ready() -> void:
	_build_silhouettes()
	_build_eye_swatches()
	for pose: String in VICTORY_POSES:
		_pose_select.add_item(pose)
	%BackButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://core/ui/TitleScreen.tscn"))
	%StartButton.pressed.connect(_on_start_pressed)
	_select_silhouette(0)
	_select_eye(0)


func _build_silhouettes() -> void:
	for i: int in 3:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(74, 96)
		btn.icon = _make_unlabeled_silhouette_icon(i)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.pressed.connect(_select_silhouette.bind(i))
		_silhouettes_box.add_child(btn)
		_silhouette_btns.append(btn)


func _make_unlabeled_silhouette_icon(kind: int) -> Texture2D:
	var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y: int in range(6, 45):
		var half := 4 if y < 13 else 7
		if kind == 0 and y >= 13 and y < 28:
			half = 9  # Ombros largos
		elif kind == 1 and y >= 24:
			half = 5 + (y - 24) / 4  # Túnica fluida
		elif kind == 2:
			half = 5 if y < 26 else 7  # Figura andrógina/esguia com manto
		for x: int in range(16 - half, 16 + half + 1):
			img.set_pixel(x, y, Color(0.88, 0.86, 0.80))
	return ImageTexture.create_from_image(img)


func _build_eye_swatches() -> void:
	for i: int in EYE_COLORS.size():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(26, 22)
		var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
		img.fill(EYE_COLORS[i]["color"] as Color)
		btn.icon = ImageTexture.create_from_image(img)
		btn.pressed.connect(_select_eye.bind(i))
		_eyes_box.add_child(btn)
		_eye_btns.append(btn)


func _select_silhouette(idx: int) -> void:
	_selected_silhouette = idx
	for i: int in _silhouette_btns.size():
		_silhouette_btns[i].modulate = Color(1.0, 0.88, 0.45) if i == idx else Color(0.65, 0.65, 0.72)


func _select_eye(idx: int) -> void:
	_selected_eye_idx = idx
	_eye_label.text = "Olhos: %s" % String(EYE_COLORS[idx]["name"])
	for i: int in _eye_btns.size():
		_eye_btns[i].modulate = Color(1.15, 1.15, 1.15) if i == idx else Color(0.65, 0.65, 0.65)


func _on_start_pressed() -> void:
	var chosen_name := _name_input.text.strip_edges()
	if chosen_name.is_empty():
		chosen_name = "Shen Yue"
	EssenceState.protagonist_profile = {
		"name": chosen_name,
		"silhouette_id": _selected_silhouette,
		"eye_color": String(EYE_COLORS[_selected_eye_idx]["name"]),
		"victory_pose": VICTORY_POSES[_pose_select.selected],
	}
	if WorldState.era_config == null:
		WorldState.reset_visible(1)
		var start_era: String = ProjectSettings.get_setting(WorldState.START_ERA_SETTING, "res://eras/act_01_tianxu/EraConfig_Act01.tres")
		WorldState.load_era(start_era)
	get_tree().change_scene_to_file("res://core/overworld/OverworldMap.tscn")

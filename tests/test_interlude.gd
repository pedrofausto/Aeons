extends RefCounted
## Testes do Interlúdio de Presença + dilema "Os Celeiros de Linhai" (Dialogic 2).

const ROOM := "res://core/interlude/InterludeRoom.tscn"
const MAP_SCENE := "res://core/overworld/OverworldMap.tscn"
const TIMELINE := "res://eras/act_01_tianxu/dialogues/celeiros_de_linhai.dtl"
const ACT01 := "res://eras/act_01_tianxu/EraConfig_Act01.tres"
const FORBIDDEN: Array[String] = ["aeon", "simulação", "simulacao", "simulacro", "mesma alma"]
## Termos extras proibidos por ato (além de FORBIDDEN). Pastas ausentes são ignoradas.
const EXTRA_FORBIDDEN: Dictionary = {
	"res://eras/act_03_ash_and_steel": ["matriz", "vida passada", "china", "carcassonne", "tianxu", "occitânia", "occitania"],
}
const SECRET_SCOPES: Array[String] = ["res://eras/act_01_tianxu", "res://eras/act_02_occitania",
	"res://eras/act_03_great_wars", "res://eras/act_04_modern", "res://core/overworld",
	"res://core/combat", "res://core/interlude", "res://docs/Lore_Simulacros"]


func run(t: Node) -> void:
	var fx := InterludeController.parse_effects("effect|alignment=10|doctrine=-15|flag=x|echo=y")
	t.check("interlude_parse_effects", fx == {"alignment": 10, "doctrine": -15, "flag": "x", "echo": "y"}, str(fx))
	t.check("interlude_parse_ignores_other", InterludeController.parse_effects("outro|a=1").is_empty())

	var timeline: Resource = load(TIMELINE)
	timeline.call("process")
	var choices: int = 0
	var signals: int = 0
	for event: Variant in timeline.get("events"):
		if event is DialogicChoiceEvent:
			choices += 1
		elif event is DialogicSignalEvent:
			signals += 1
	t.check("granaries_timeline_two_choices", choices == 2 and signals == 2, "choices=%d signals=%d" % [choices, signals])

	await _play_choice(t, 1)
	t.check("granaries_distribute_effects", WorldState.alignment == 60 and WorldState.popular_support == 65
		and WorldState.doctrine == -15 and WorldState.resources == 500
		and WorldState.has_flag("act1_granaries_distributed") and "shared_linhai_rice" in WorldState.act_echoes,
		"al=%d ap=%d dt=%d" % [WorldState.alignment, WorldState.popular_support, WorldState.doctrine])

	t.check("interlude_marked_once_per_act", TIMELINE in WorldState.completed_interludes
		and not InterludeManager.is_eligible(TIMELINE, WorldState.era_config))

	await _play_choice(t, 2)
	t.check("granaries_confiscate_effects", WorldState.resources == 750 and WorldState.popular_support == 40
		and WorldState.doctrine == 15 and WorldState.alignment == 50 and WorldState.has_flag("act1_granaries_confiscated"),
		"ouro=%d ap=%d dt=%d" % [WorldState.resources, WorldState.popular_support, WorldState.doctrine])

	# Integração: a libertação de Linhai abre o interlúdio sobre o mapa
	_reset()
	var map := (load(MAP_SCENE) as PackedScene).instantiate() as OverworldMap
	map.auto_tick = false
	t.get_tree().root.add_child(map)
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	var director: EncounterDirector = map.get_node("%EncounterDirector")
	t.check("liberation_opens_interlude", director.active_interlude != null and not map.visible
		and WorldState.has_flag("liberated_linhai"))
	await _drive_dialogic(t, director.active_interlude, 1)
	await t.get_tree().process_frame
	t.check("interlude_returns_to_map", director.active_interlude == null and map.visible
		and WorldState.popular_support == 65)

	# A escolha vira eco filosófico oculto ao arquivar o ato (Derrota Falsa)
	EssenceState.archive_act_and_reset_visible(1)
	t.check("granaries_echo_archived", "shared_linhai_rice" in EssenceState.philosophical_echoes
		and WorldState.act_echoes.is_empty() and WorldState.current_act == 2)
	map.queue_free()
	await t.get_tree().process_frame
	_reset()

	await _test_ephemeral(t)
	t.check("lore_secrecy_acts_1_to_4", _scan_forbidden().is_empty(), str(_scan_forbidden()))


## Encontro efêmero (Ato V): shader de dissolução + nunca se repete, nem após a Derrota Falsa.
func _test_ephemeral(t: Node) -> void:
	_reset()
	var eph := WorldState.era_config.duplicate() as EraConfig
	eph.interlude_style = "ephemeral_metaphysical"
	eph.dissolve_interlude_shader = load("res://core/interlude/shaders/ephemeral_fade.gdshader")
	WorldState.era_config = eph
	t.check("ephemeral_overlay_material", InterludeManager.overlay_material(eph) != null
		and InterludeManager.overlay_material(load(ACT01)) == null)
	var room := (load(ROOM) as PackedScene).instantiate()
	room.call("setup", TIMELINE, "", "")
	t.get_tree().root.add_child(room)
	for i: int in 20:
		await t.get_tree().process_frame
	var overlay: ColorRect = room.get_node("%EphemeralOverlay")
	t.check("ephemeral_shader_renders", overlay.visible and float((overlay.material as ShaderMaterial).get_shader_parameter("dissolve")) > 0.0)
	await _drive_dialogic(t, room, 1)
	t.check("ephemeral_meeting_recorded", "celeiros_de_linhai" in EssenceState.ephemeral_meetings_seen)
	WorldState.reset_visible(5)
	WorldState.era_config = eph
	t.check("ephemeral_never_repeats", not InterludeManager.is_eligible(TIMELINE, eph)
		and InterludeManager.is_eligible(TIMELINE, load(ACT01)))
	_reset()


func _reset() -> void:
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)


func _play_choice(t: Node, choice: int) -> void:
	_reset()
	var room := (load(ROOM) as PackedScene).instantiate()
	room.call("setup", TIMELINE, "Os Celeiros de Linhai", "linhai")
	t.get_tree().root.add_child(room)
	var steps: int = await _drive_dialogic(t, room, choice)
	if is_instance_valid(room):
		print("INFO|interlúdio não terminou após %d passos" % steps)
		t.get_node("/root/Dialogic").call("end_timeline", true)
		room.free()


## Avança o texto e escolhe a opção `choice` (1 = primeira) até o interlúdio fechar.
func _drive_dialogic(t: Node, room: Node, choice: int) -> int:
	var dialogic: Node = t.get_node("/root/Dialogic")
	for i: int in 300:
		if not is_instance_valid(room) or not room.is_inside_tree():
			return i
		var choices: Node = dialogic.get("Choices")
		# Repete a escolha: o Dialogic ignora cliques durante o bloqueio anti-duplo-clique.
		var button := choices.call("get_choice_button", choice) as Control
		if button != null and button.is_visible_in_tree():
			choices.call("select_choice", choice)
		else:
			dialogic.get("Inputs").call("handle_input")
		await t.get_tree().create_timer(0.12).timeout
	return 300


func _scan_forbidden() -> Array[String]:
	var hits: Array[String] = []
	for scope: String in SECRET_SCOPES:
		_scan_dir(scope, hits, FORBIDDEN)
	for scope: String in EXTRA_FORBIDDEN:
		var words: Array[String] = []
		words.assign(EXTRA_FORBIDDEN[scope])
		_scan_dir(scope, hits, words)
	return hits


func _scan_dir(path: String, hits: Array[String], forbidden: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_scan_dir(path.path_join(sub), hits, forbidden)
	for file: String in dir.get_files():
		if file.get_extension() in ["dtl", "tres", "tscn", "gd", "json", "md"]:
			var text: String = FileAccess.get_file_as_string(path.path_join(file)).to_lower()
			for word: String in forbidden:
				if word in text:
					hits.append("%s:%s" % [file, word])

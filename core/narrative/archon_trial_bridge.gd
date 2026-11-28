class_name ArchonTrialBridge
extends Resource
## Recurso nativo do Godot 4 que também funciona como ponte para o Dialogic 2.
## Salve o JSON em res://data/archon_questions.json e chame
## ArchonTrialBridge.bake_tres_from_json() para gerar o .tres editável no Inspector.

const ARCHON_ORDER: Array[String] = ["athoth", "eloaiou", "astaphaios", "yao", "sabaoth", "adonin", "sabbede"]

@export var hide_archon_names_until_act: int = 5
@export var archons: Array[Dictionary] = []
@export var questions: Array[Dictionary] = []


static func load_from_json(json_path: String = "res://data/archon_questions.json") -> ArchonTrialBridge:
	var bank := ArchonTrialBridge.new()
	if not FileAccess.file_exists(json_path):
		return bank
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	if not (parsed is Dictionary):
		return bank
	var data := parsed as Dictionary
	bank.hide_archon_names_until_act = int(data.get("hide_archon_names_until_act", 5))
	for a: Variant in data.get("archons", []):
		if a is Dictionary:
			bank.archons.append(a as Dictionary)
	for q: Variant in data.get("questions", []):
		if q is Dictionary:
			bank.questions.append(q as Dictionary)
	return bank


static func bake_tres_from_json(
	json_path: String = "res://data/archon_questions.json",
	tres_path: String = "res://data/archon_questions_db.tres"
) -> ArchonTrialBridge:
	var bank := load_from_json(json_path)
	ResourceSaver.save(bank, tres_path)
	return bank


## Sorteia 7 perguntas (1 por Arconte) no estilo Tarô inicial de Ogre Battle.
func draw_seven_archon_trial(exclude_ids: Array[String] = []) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	for aid: String in ARCHON_ORDER:
		var pool: Array[Dictionary] = questions.filter(
			func(item: Dictionary) -> bool: return String(item["archon_id"]) == aid and not exclude_ids.has(String(item["id"]))
		)
		if pool.is_empty():
			pool = questions.filter(func(item: Dictionary) -> bool: return String(item["archon_id"]) == aid)
		if not pool.is_empty():
			selected.append(pool.pick_random())
	return selected


## Aplica os pesos em WorldState, EssenceState e sincroniza com Dialogic 2.
func apply_choice(question_id: String, choice_key: String, world_state: Node, essence_state: Node) -> Dictionary:
	for q: Dictionary in questions:
		if String(q["id"]) != question_id:
			continue
		for ch_var: Variant in q["choices"]:
			var ch := ch_var as Dictionary
			if String(ch["key"]) != choice_key:
				continue
			if world_state != null:
				world_state.alignment = clampi(int(world_state.alignment) + int(ch["alignment"]), 0, 100)
				world_state.popular_support = clampi(int(world_state.popular_support) + int(ch["popular_support"]), 0, 100)
				world_state.doctrine = clampi(int(world_state.doctrine) + int(ch["doctrine"]), -100, 100)
			if essence_state != null:
				essence_state.essence_lucidity = clampi(int(essence_state.essence_lucidity) + int(ch["essence_lucidity"]), 0, 100)
			var tree := Engine.get_main_loop() as SceneTree
			var dlg: Node = tree.root.get_node_or_null("Dialogic") if tree != null else null
			if dlg != null and dlg.get("VAR") != null:
				var dvar: Variant = dlg.get("VAR")
				if world_state != null:
					dvar.set("alignment", world_state.alignment)
					dvar.set("popular_support", world_state.popular_support)
					dvar.set("doctrine", world_state.doctrine)
				if essence_state != null:
					dvar.set("essence_lucidity", essence_state.essence_lucidity)
			return ch
	return {}


## Gera linhas prontas para uma DialogicTimeline (mantém Arconte oculto até o Ato V).
func build_dialogic_events(question_id: String, current_act: int = 1) -> Array[String]:
	for q: Dictionary in questions:
		if String(q["id"]) != question_id:
			continue
		var prefix: String = "%s: " % String(q["archon_id"]).capitalize() if current_act >= hide_archon_names_until_act else ""
		var lines: Array[String] = [prefix + String(q["prompt"])]
		for ch_var: Variant in q["choices"]:
			var ch := ch_var as Dictionary
			lines.append("- " + String(ch["text"]))
			lines.append("\t[signal arg=\"archon_choice:%s:%s\"]" % [String(q["id"]), String(ch["key"])])
		return lines
	return []

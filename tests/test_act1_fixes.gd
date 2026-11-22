extends RefCounted
## Regressões das 3 correções do Ato I: Hanmen + Cortejo noturno, Astrônomo Cego e
## promoção que consome o Talismã de Cinábrio. Emite ACT1_FIXES_SMOKE_PASS.

const MAP_SCENE := "res://core/overworld/OverworldMap.tscn"
const ACT01 := "res://eras/act_01_tianxu/EraConfig_Act01.tres"


func run(t: Node) -> void:
	var failed_before: int = t.failed
	await _test_hanmen(t)
	for method: String in ["_test_astronomer", "_test_talisman_promotion"]:
		if has_method(method):
			await call(method, t)
	if t.failed == failed_before:
		print("ACT1_FIXES_SMOKE_PASS")


func _reset() -> void:
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	WorldState.set_flag("liberated_linhai")


func _open_map(t: Node) -> OverworldMap:
	var map := (load(MAP_SCENE) as PackedScene).instantiate() as OverworldMap
	map.auto_tick = false
	t.get_tree().root.add_child(map)
	await t.get_tree().process_frame
	return map


## (a) Cortejo só em Hanmen e só à noite; nós novos na borda oeste de Nanlu.
func _test_hanmen(t: Node) -> void:
	_reset()
	var map: OverworldMap = await _open_map(t)
	var pass_node: MapNodeData = (map.nodes["hanmen_pass"] as MapNode).data
	var gate_node: MapNodeData = (map.nodes["hanmen_gate"] as MapNode).data
	t.check("hanmen_nodes_west_of_nanlu", pass_node.region_id == "hanmen" and pass_node.terrain == "mountain"
		and gate_node.region_id == "hanmen" and gate_node.node_type == MapNodeData.NodeType.FORTRESS
		and "hanmen_pass" in (map.nodes["linhai"] as MapNode).data.neighbors
		and pass_node.map_position.x < (map.nodes["linhai"] as MapNode).data.map_position.x
		and MapGraph.find_path(map.call("_graph"), "linhai", "hanmen_gate") == ["hanmen_pass", "hanmen_gate"])
	var wei_bo_on_gate: bool = false
	for token: SquadToken in map.tokens:
		if token.squad.squad_id == "guarda_de_hanmen" and token.squad.current_node_id == "hanmen_gate":
			wei_bo_on_gate = token.squad.get_leader().unit_name == "General Wei Bo"
	t.check("hanmen_gate_boss_garrison", wei_bo_on_gate)

	var cortejo_spawns: Array[String] = []
	var other_spawns: int = 0
	for day: int in 60:
		for time: String in ["day", "night"]:
			WorldState.day_count = 2 + day
			WorldState.time_of_day = time
			for squad: SquadData in map.spawner.try_spawn():
				if squad.squad_id == "cortejo_de_jiangshi":
					var region: String = (map.nodes[squad.current_node_id] as MapNode).data.region_id
					cortejo_spawns.append("%s@%s" % [region, time])
				else:
					other_spawns += 1
			for token: SquadToken in map.tokens.duplicate():
				if token.squad.is_roaming:
					map.remove_token(token)
	t.check("cortejo_spawns_only_hanmen_at_night", not cortejo_spawns.is_empty()
		and cortejo_spawns.all(func(s: String) -> bool: return s == "hanmen@night") and other_spawns > 0,
		"cortejos=%s outros=%d" % [str(cortejo_spawns.slice(0, 6)), other_spawns])
	var nanlu := load("res://eras/act_01_tianxu/encounters/nanlu_encounters.tres") as EncounterTable
	var in_nanlu: bool = false
	for entry: EncounterEntry in nanlu.entries:
		in_nanlu = in_nanlu or entry.squad.squad_id == "cortejo_de_jiangshi"
	t.check("cortejo_removed_from_nanlu", not in_nanlu)
	var hanmen := load("res://eras/act_01_tianxu/encounters/hanmen_encounters.tres") as EncounterTable
	var rng := RandomNumberGenerator.new()
	t.check("cortejo_entry_requires_hanmen_night", hanmen.pick(rng, "night", 3.0, "hanmen") != null
		and hanmen.pick(rng, "day", 3.0, "hanmen") == null and hanmen.pick(rng, "night", 3.0, "nanlu") == null)

	var ally: SquadToken = map.selected_token
	var plains: float = ally.march_speed(55.0, "plains")
	t.check("mountain_terrain_slows_march", is_equal_approx(ally.march_speed(55.0, "mountain"), plains * SquadToken.MOUNTAIN_FACTOR))
	for token: SquadToken in map.tokens.duplicate():
		if not token.is_player() and token.squad.squad_id != "guarda_de_hanmen":
			map.remove_token(token)
	WorldState.capture_node("forte_regencia", "player")
	map.get_node("%EncounterDirector").call("check_victory")
	t.check("hanmen_gate_optional_for_victory", WorldState.has_flag("act_victory"))
	map.queue_free()
	await t.get_tree().process_frame


const RICE := "res://eras/act_01_tianxu/dialogues/celeiros_de_linhai.dtl"
const ASTRONOMER := "res://eras/act_01_tianxu/dialogues/o_astronomo_cego.dtl"
const HONOR_FLAG := "act1_blind_astronomer_protected"


## (b) Dilema do Astrônomo Cego pelo fluxo normal de jogo.
func _test_astronomer(t: Node) -> void:
	# Proteger: grava a decisão no EssenceState, sobe Alinhamento e Apoio.
	_reset()
	_quiet()
	var map: OverworldMap = await _open_map(t)
	var ally: SquadToken = map.selected_token
	var director: EncounterDirector = map.get_node("%EncounterDirector")
	var opened: String = await _march(t, map, ally, "templo_bambu", {ASTRONOMER: 1}, 40.0)
	t.check("astronomer_event_on_first_visit", opened == ASTRONOMER and WorldState.get_node_faction("templo_bambu") == "player")
	t.check("astronomer_protect_records_flag", EssenceState.decisions.get(HONOR_FLAG) == true
		and WorldState.alignment == 60 and WorldState.popular_support == 58
		and "protected_star_charts" in EssenceState.aeon_resistance_flags, "al=%d ap=%d" % [WorldState.alignment, WorldState.popular_support])
	# Só uma vez: nem o registro direto nem um novo sinal da timeline alteram a decisão.
	t.check("astronomer_flag_set_once", not EssenceState.record_decision(HONOR_FLAG, false)
		and not InterludeManager.is_eligible(ASTRONOMER, WorldState.era_config))
	var room := (load("res://core/interlude/InterludeRoom.tscn") as PackedScene).instantiate()
	room.call("apply_signal_argument", "effect|decision=%s:false|resources=300|alignment=-10" % HONOR_FLAG)
	room.free()
	t.check("astronomer_replay_ignored", EssenceState.decisions[HONOR_FLAG] == true and WorldState.resources == 500
		and WorldState.alignment == 60)
	map.queue_free()
	await t.get_tree().process_frame

	# Entregar: grava false, dá ouro e reduz Alinhamento.
	_reset()
	_quiet()
	map = await _open_map(t)
	await _march(t, map, map.selected_token, "templo_bambu", {ASTRONOMER: 2}, 40.0)
	t.check("astronomer_surrender_records_false", EssenceState.decisions.has(HONOR_FLAG)
		and EssenceState.decisions[HONOR_FLAG] == false and WorldState.resources >= 800 and WorldState.alignment == 40,
		"ouro=%d al=%d" % [WorldState.resources, WorldState.alignment])
	map.queue_free()
	await t.get_tree().process_frame

	# Rota de honra alcançável jogando: arroz distribuído + Astrônomo protegido -> Portão de Hanmen.
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	_quiet()
	map = await _open_map(t)
	ally = map.selected_token
	await _march(t, map, ally, "templo_bambu", {RICE: 1, ASTRONOMER: 1}, 40.0)
	var honor_alignment: float = ally.squad.average_alignment()
	var won: bool = false
	for attempt: int in 6:
		await _march(t, map, ally, "hanmen_gate", {}, 40.0)
		if WorldState.get_node_faction("hanmen_gate") == "player":
			won = true
			break
		_rest(map, 5)
	t.check("honor_route_reachable_in_play", won and honor_alignment >= 70.0
		and WorldState.has_flag("hanmen_pact_of_honor"), "alinhamento=%.1f venceu=%s" % [honor_alignment, won])
	map.queue_free()
	await t.get_tree().process_frame


func _quiet() -> void:
	var quiet := WorldState.era_config.duplicate() as EraConfig
	quiet.encounter_tables = []
	WorldState.era_config = quiet


func _rest(map: OverworldMap, days: int) -> void:
	WorldState.set_paused(false)
	for i: int in int(days * map.seconds_per_day / 0.05):
		map.step(0.05)


## Marcha até `target` jogando: resolve batalhas (Focar Fraco) e escolhe nos interlúdios.
## Retorna o último interlúdio aberto. Para ao chegar, ao perder ou no tempo-limite.
func _march(t: Node, map: OverworldMap, ally: SquadToken, target: String, choices: Dictionary, seconds: float) -> String:
	var director: EncounterDirector = map.get_node("%EncounterDirector")
	var opened: String = ""
	var elapsed: float = 0.0
	while elapsed < seconds:
		if director.active_interlude:
			opened = String(director.active_interlude.get("timeline_path"))
			await _drive(t, director.active_interlude, int(choices.get(opened, 1)))
			await t.get_tree().process_frame
			continue
		if director.active_battle:
			var arena: BattleArena = director.active_battle
			arena.step_seconds = 0.0
			await arena.start_battle(TacticalOrder.Order.FOCUS_WEAK)
			var lost: bool = not bool(arena.result["effects"]["player_won"])
			arena.closed.emit(arena.result)
			await t.get_tree().process_frame
			if lost:
				return opened
			continue
		if ally.squad.current_node_id == target and not ally.is_moving():
			await t.get_tree().process_frame
			if not director.is_busy():
				return opened
			continue
		WorldState.set_paused(false)
		if not ally.is_moving():
			map.order_move(ally, target)
		map.step(0.05)
		elapsed += 0.05
	return opened


func _drive(t: Node, room: Node, choice: int) -> void:
	var dialogic: Node = t.get_node("/root/Dialogic")
	for i: int in 300:
		if not is_instance_valid(room) or not room.is_inside_tree():
			return
		var button := dialogic.get("Choices").call("get_choice_button", choice) as Control
		if button != null and button.is_visible_in_tree():
			dialogic.get("Choices").call("select_choice", choice)
		else:
			dialogic.get("Inputs").call("handle_input")
		await t.get_tree().create_timer(0.12).timeout


const TALISMAN := "res://eras/act_01_tianxu/items/talisma_cinabrio.tres"


## (c) Promoção especial do Fangshi consome 1 talisma_cinabrio (lógica + UI).
## Árvore do ledger: Fangshi -> Daoshi (honrada) / Alquimista Sombrio (sombria, talismã) + Xian (mítica, elixir).
func _test_talisman_promotion(t: Node) -> void:
	_reset()
	_quiet()
	var fangshi := load("res://eras/act_01_tianxu/classes/fangshi.tres") as UnitClassData
	var xian := load("res://eras/act_01_tianxu/classes/xian.tres") as UnitClassData
	var wu := load("res://eras/act_01_tianxu/classes/alquimista_sombrio.tres") as UnitClassData
	var daoshi := load("res://eras/act_01_tianxu/classes/daoshi_healer.tres") as UnitClassData
	t.check("talisman_item_id_and_requirement", (load(TALISMAN) as ItemData).item_id == "talisma_cinabrio"
		and xian.required_item_id == &"elixir_pengming" and wu.required_item_id == &"talisma_cinabrio"
		and fangshi.promotion_good == daoshi and fangshi.promotion_evil == wu and xian in fangshi.promotes_to
		and (load("res://eras/act_01_tianxu/classes/youxia.tres") as UnitClassData).required_item_id == &"")
	var dark := UnitInstance.create(fangshi, "Sombrio", 10, 3, false, 20)
	t.check("fangshi_low_alignment_branch_wu", PromotionRules.options_for(dark).size() == 1
		and PromotionRules.options_for(dark)[0]["target"] == wu)

	var map: OverworldMap = await _open_map(t)
	var squad: SquadData = map.selected_token.squad
	var yan: UnitInstance = null
	for unit: UnitInstance in squad.units:
		if unit.class_data == fangshi:
			yan = unit
	t.check("guard_has_fangshi_in_play", yan != null)
	yan.level = 10
	yan.alignment = 20
	t.check("promotion_blocked_without_item", not PromotionRules.promote(yan, wu) and yan.class_data == fangshi
		and squad.promote_eligible().all(func(s: String) -> bool: return not s.begins_with(yan.unit_name)))
	var hud: OverworldHUD = map.get_node("%HUD")
	hud.refresh()
	var promote_button: Button = map.get_node("%PromoteButton")
	promote_button.pressed.emit()
	var panel: PromotionPanel = hud.promotion_panel
	await t.get_tree().process_frame
	var button := _find_button(panel, "Promote_Yan Shu_alquimista_sombrio")
	t.check("promotion_ui_blocks_and_shows_requirement", panel.visible and promote_button.visible and button != null
		and button.disabled and "Talismã de Cinábrio" in button.text and "(você tem 0)" in button.text,
		button.text if button else "sem botão")

	WorldState.add_item(load(TALISMAN))
	WorldState.add_item(load(TALISMAN))
	panel.rebuild()
	await t.get_tree().process_frame
	button = _find_button(panel, "Promote_Yan Shu_alquimista_sombrio")
	t.check("promotion_ui_unlocks_with_item", button != null and not button.disabled and "consome 1" in button.text)
	button.pressed.emit()
	await t.get_tree().process_frame
	t.check("promotion_consumes_one_talisman", yan.class_data == wu and WorldState.count_item("talisma_cinabrio") == 1
		and _find_button(panel, "Promote_Yan Shu_alquimista_sombrio") == null, "talismãs=%d" % WorldState.count_item("talisma_cinabrio"))
	var cortejo := load("res://eras/act_01_tianxu/encounters/squad_cortejo_de_jiangshi.tres") as SquadData
	t.check("talisman_obtainable_from_cortejo", cortejo.rare_drop != null and cortejo.rare_drop.item_id == "talisma_cinabrio")
	map.queue_free()
	await t.get_tree().process_frame


func _find_button(root: Node, button_name: String) -> Button:
	for node: Node in root.find_children("*", "Button", true, false):
		if node.name == button_name and not node.is_queued_for_deletion():
			return node as Button
	return null

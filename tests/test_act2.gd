extends RefCounted
## Ato II — Cidadela de Carcassonne: mapa, classes, regra da água e campanha jogável.
## Emite ACT2_CARCASSONNE_PASS.

const MAP_SCENE := "res://core/overworld/OverworldMap.tscn"
const ACT01 := "res://eras/act_01_tianxu/EraConfig_Act01.tres"
const CLS := "res://eras/act_02_occitania/classes/%s.tres"


func run(t: Node) -> void:
	var failed_before: int = t.failed
	# Chega-se ao Ato II pela Derrota Falsa do Ato I (fluxo real).
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	EssenceState.archive_act_and_reset_visible(1)
	var era: EraConfig = WorldState.era_config
	t.check("act2_loaded_by_transition", WorldState.current_act == 2 and era.act_number == 2
		and era.enable_siege_water_rule and era.map_nodes.size() == 4 and era.resource_label == "Prata")
	_quiet()

	var ok_classes: bool = true
	for id: String in ["sergent_darmes", "faydit", "routier", "lanceiro_escudeiro", "arbaletrier", "irmao_caridade",
			"parfait", "inquisidor", "trovador", "erudito_boticario"]:
		var cls := load(CLS % id) as UnitClassData
		ok_classes = ok_classes and cls != null and cls.era_id == 2 and cls.front_action != null and cls.back_action != null
	t.check("act2_classes_load", ok_classes)
	var sergent := load(CLS % "sergent_darmes") as UnitClassData
	var brother := load(CLS % "irmao_caridade") as UnitClassData
	t.check("act2_promotions_branch", UnitInstance.create(sergent, "a", 4, 0, false, 80).get_eligible_promotions() == [load(CLS % "faydit")]
		and UnitInstance.create(sergent, "b", 4, 0, false, 10).get_eligible_promotions() == [load(CLS % "routier")]
		and UnitInstance.create(brother, "c", 4, 5, false, 90).get_eligible_promotions() == [load(CLS % "parfait")]
		and UnitInstance.create(brother, "d", 4, 5, false, 5).get_eligible_promotions() == [load(CLS % "inquisidor")])

	var map := (load(MAP_SCENE) as PackedScene).instantiate() as OverworldMap
	map.auto_tick = false
	t.get_tree().root.add_child(map)
	await t.get_tree().process_frame
	t.check("act2_carcassonne_map", map.nodes.has("cite_carcassonne") and map.nodes.has("burgo_sao_vicente")
		and map.nodes.has("pontes_aude") and map.nodes.has("castelo_cabaret") and map.tokens.size() == 4
		and WorldState.get_node_faction("castelo_cabaret") == "player" and WorldState.get_node_faction("cite_carcassonne") == "enemy"
		and (map.nodes["cite_carcassonne"] as MapNode).data.water_source_node == "pontes_aude", "tokens=%d" % map.tokens.size())

	# Regra da água: Aude neutro -> sem sede; Aude do jogador -> a guarnição da Cité definha.
	var garrison: SquadData = _squad_on(map, "guarnicao_de_montclair")
	t.check("siege_no_thirst_while_water_neutral", map.siege_rule.apply().is_empty())
	WorldState.capture_node("pontes_aude", "player")
	var before: float = garrison.vitality_ratio()
	var parched := map.siege_rule.apply()
	t.check("siege_water_cut_weakens_garrison", parched == ["cite_carcassonne"] and garrison.vitality_ratio() < before
		and garrison.get_living_units().size() == garrison.units.size(), str(parched))
	for day: int in 30:
		map.siege_rule.apply()
	t.check("siege_thirst_never_kills", garrison.get_living_units().size() == garrison.units.size()
		and garrison.units.all(func(u: UnitInstance) -> bool: return u.hp >= 1))
	# Inverso: o jogador segura a Cité, o inimigo a água -> o jogador sofre.
	var ally: SquadToken = map.selected_token
	WorldState.capture_node("cite_carcassonne", "player")
	WorldState.capture_node("pontes_aude", "enemy")
	ally.teleport_to("cite_carcassonne", (map.nodes["cite_carcassonne"] as MapNode).position)
	var ally_before: float = ally.squad.vitality_ratio()
	map.siege_rule.apply()
	t.check("siege_cuts_both_ways", ally.squad.vitality_ratio() < ally_before)
	map.queue_free()
	await t.get_tree().process_frame

	await _campaign(t)
	var act1 := load(ACT01) as EraConfig
	t.check("siege_rule_off_in_act1", not act1.enable_siege_water_rule)
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	if t.failed == failed_before:
		print("ACT2_CARCASSONNE_PASS")


## Campanha jogada: Burgo -> Pontes (corta a água) -> espera a sede -> Cité.
func _campaign(t: Node) -> void:
	EssenceState.reset_all()
	WorldState.reset_visible(2)
	WorldState.load_era("res://eras/act_02_occitania/EraConfig_Act02.tres")
	_quiet()
	var map := (load(MAP_SCENE) as PackedScene).instantiate() as OverworldMap
	map.auto_tick = false
	t.get_tree().root.add_child(map)
	await t.get_tree().process_frame
	var ally: SquadToken = map.selected_token
	var battles: Array[String] = []
	for leg: String in ["burgo_sao_vicente", "pontes_aude"]:
		for attempt: int in 4:
			await _march(t, map, ally, leg, battles)
			if WorldState.get_node_faction(leg) == "player":
				break
			await _idle(t, map, 4, battles)
	t.check("act2_water_taken", WorldState.get_node_faction("pontes_aude") == "player", str(battles))
	var garrison: SquadData = _squad_on(map, "guarnicao_de_montclair")
	var fresh: float = garrison.vitality_ratio() if garrison else 0.0
	await _idle(t, map, 6, battles)  # O cerco faz efeito enquanto a Companhia guarda as Pontes.
	t.check("act2_siege_wears_down_cite", garrison != null and garrison.vitality_ratio() < fresh)
	for attempt: int in 6:
		await _march(t, map, ally, "cite_carcassonne", battles)
		if WorldState.has_flag("act_victory"):
			break
		await _idle(t, map, 4, battles)
	t.check("act2_carcassonne_retaken", WorldState.get_node_faction("cite_carcassonne") == "player"
		and WorldState.has_flag("act_victory"), str(battles))
	print("INFO|Ato II batalhas -> %s" % str(battles))
	map.queue_free()
	await t.get_tree().process_frame


func _quiet() -> void:
	var quiet := WorldState.era_config.duplicate() as EraConfig
	quiet.encounter_tables = []
	WorldState.era_config = quiet


func _squad_on(map: OverworldMap, squad_id: String) -> SquadData:
	for token: SquadToken in map.tokens:
		if token.squad.squad_id == squad_id:
			return token.squad
	return null


## Espera `days` dias parado, resolvendo qualquer encontro que chegue (como o jogador faria).
func _idle(t: Node, map: OverworldMap, days: int, battles: Array[String]) -> void:
	var director: EncounterDirector = map.get_node("%EncounterDirector")
	var steps: int = int(days * map.seconds_per_day / 0.05)
	while steps > 0:
		if director.active_battle:
			await _resolve(t, director.active_battle, battles)
			continue
		WorldState.set_paused(false)
		map.step(0.05)
		steps -= 1


func _resolve(t: Node, arena: BattleArena, battles: Array[String]) -> bool:
	arena.step_seconds = 0.0
	await arena.start_battle(TacticalOrder.Order.FOCUS_WEAK)
	battles.append("%s:%s/%s" % [arena.enemy_squad.squad_id, arena.result["winner"], arena.result["victory_type"]])
	var won: bool = bool(arena.result["effects"]["player_won"])
	arena.closed.emit(arena.result)
	await t.get_tree().process_frame
	return won


func _march(t: Node, map: OverworldMap, ally: SquadToken, target: String, battles: Array[String]) -> void:
	var director: EncounterDirector = map.get_node("%EncounterDirector")
	var elapsed: float = 0.0
	while elapsed < 40.0:
		if director.active_battle:
			if not await _resolve(t, director.active_battle, battles):
				return
			continue
		if ally.squad.current_node_id == target and not ally.is_moving():
			return
		WorldState.set_paused(false)
		if not ally.is_moving():
			map.order_move(ally, target)
		map.step(0.05)
		elapsed += 0.05

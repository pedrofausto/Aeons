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

	await _test_class_tree(t)
	_quiet()

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


const TREE: Dictionary = {
	"sergent_darmes": ["faydit", "routier", "cavaleiro_hospitalario"], "lanceiro_escudeiro": ["chevalier_languedoc", "quebra_muralhas"],
	"arbaletrier": ["batedor_pireneus", "sicario_inquisitorial"], "erudito_boticario": ["alquimista_hermetico", "engenheiro_fogo"],
	"irmao_caridade": ["parfait", "inquisidor"], "trovador": ["menestrel_resistencia", "arauto_cruzada"],
}


func _cls(id: String) -> UnitClassData:
	return load(CLS % id) as UnitClassData


func _unit(id: String, level: int, alignment: int, charisma: int = 50, slot: int = 0) -> UnitInstance:
	return UnitInstance.create(_cls(id), id, level, slot, false, alignment, charisma)


func _option(unit: UnitInstance, target_id: String) -> Dictionary:
	for option: Dictionary in PromotionRules.options_for(unit):
		if (option["target"] as UnitClassData).class_id == target_id:
			return option
	return {}


## Árvore mesclada (Specs_Classes_Ato2 + Adendo) e os efeitos novos do motor.
func _test_class_tree(t: Node) -> void:
	var tree_ok: bool = true
	for base: String in TREE:
		var targets: Array = _cls(base).get_promotion_targets().map(func(c: UnitClassData) -> String: return c.class_id)
		tree_ok = tree_ok and _cls(base).tier == 1 and targets == TREE[base]
		for elite: String in TREE[base]:
			tree_ok = tree_ok and _cls(elite).tier == 2 and _cls(elite).era_id == 2 and _cls(elite).min_level >= 9
	t.check("act2_class_tree_19", tree_ok and WorldState.era_config.unit_classes.size() == 19)

	# Doutrina decide entre Faydit (Revolucionária) e Hospitalário (Pacifista); Carisma barra.
	var veteran := _unit("sergent_darmes", 10, 80, 65)
	WorldState.doctrine = 30
	var rev_faydit := _option(veteran, "faydit")
	var rev_hosp := _option(veteran, "cavaleiro_hospitalario")
	WorldState.doctrine = -30
	var pac_faydit := _option(veteran, "faydit")
	var pac_hosp := _option(veteran, "cavaleiro_hospitalario")
	t.check("act2_doctrine_branches_sergent", rev_faydit.get("available") == true and rev_hosp.get("doctrine_ok") == false
		and pac_faydit.get("doctrine_ok") == false and pac_hosp.get("available") == true)
	t.check("act2_charisma_and_level_gate", _option(_unit("sergent_darmes", 10, 80, 40), "faydit").is_empty()
		and _option(_unit("sergent_darmes", 9, 80, 65), "faydit").is_empty()
		and _option(_unit("sergent_darmes", 9, 20), "routier").get("available") == true)
	WorldState.doctrine = -40
	var monk := _unit("irmao_caridade", 10, 90)
	var parfait_open: bool = _option(monk, "parfait").get("available") == true
	WorldState.set_flag("act2_aude_poisoned")
	t.check("act2_parfait_refuses_after_poison", parfait_open and _option(monk, "parfait").get("forbidden") == true
		and not PromotionRules.promote(monk, _cls("parfait")))
	WorldState.doctrine = 0

	# Efeitos de combate novos.
	var state := SkillMath.new_state()
	var knight := _unit("sergent_darmes", 5, 50)
	var foe := _unit("sergent_darmes", 5, 50)
	var plain_hit: int = SkillMath.hit(knight, foe, _cls("sergent_darmes").front_action, 100, state).x
	var guard_squad := SquadData.new()
	guard_squad.units.append(foe)
	SkillMath.apply_ally_buff(_cls("cavaleiro_hospitalario").front_action, guard_squad, state)
	t.check("act2_hospitaller_guard", SkillMath.hit(knight, foe, _cls("sergent_darmes").front_action, 100, state).x < plain_hit)
	var war := SquadData.new()
	war.units.append_array([_unit("faydit", 10, 70, 60, 0), _unit("arbaletrier", 3, 50, 50, 3)])
	var cry_state := SkillMath.new_state()
	SkillMath.apply_ally_buff(_cls("faydit").back_action, war, cry_state)
	t.check("act2_faydit_cry_buffs_all", (cry_state["buff"] as Dictionary).size() == 2)

	var pacifists := SquadData.new()
	pacifists.units.append_array([_unit("parfait", 10, 90, 50, 0), _unit("parfait", 10, 90, 50, 3)])
	var weak := SquadData.new()
	weak.units.append_array([_unit("lanceiro_escudeiro", 1, 50, 50, 0), _unit("arbaletrier", 1, 50, 50, 3)])
	var log_peace := CombatResolver.resolve(pacifists, weak)
	t.check("act2_parfait_non_lethal_morale_win", weak.get_living_units().size() == 2
		and CombatResolver.get_result(log_peace).get("victory_type") == "morale_break", str(CombatResolver.get_result(log_peace)))

	var band := SquadData.new()
	band.units.append_array([_unit("sergent_darmes", 6, 60, 50, 0), _unit("menestrel_resistencia", 12, 80, 75, 3)])
	var log_bard := CombatResolver.resolve(band, _squad_of([["sergent_darmes", 6]]))
	t.check("act2_minstrel_extra_action", log_bard.any(func(e: Dictionary) -> bool: return e["type"] == "extra_action"))
	var scouts := SquadData.new()
	scouts.units.append(_unit("batedor_pireneus", 10, 70, 50, 3))
	var targets := _squad_of([["sergent_darmes", 6], ["arbaletrier", 1]])
	targets.units[1].slot = 1
	var first_hit: Dictionary = {}
	for event: Dictionary in CombatResolver.resolve(scouts, targets):
		if event["type"] == "action" and event["actor_side"] == "attacker":
			first_hit = event
			break
	t.check("act2_scout_targets_weakest", int(first_hit.get("target_index", -1)) == 1, str(first_hit))

	# Mapa: perfis de movimento, XP do Ato II e reputação ao libertar.
	var riders := _squad_of([["chevalier_languedoc", 11]])
	var climbers := _squad_of([["faydit", 10]])
	t.check("act2_movement_profiles", is_equal_approx(riders.terrain_factor("plains"), 1.3)
		and is_equal_approx(riders.terrain_factor("mountain"), 0.5) and is_equal_approx(climbers.terrain_factor("mountain"), 1.0)
		and is_equal_approx(_squad_of([["sergent_darmes", 1]]).terrain_factor("mountain"), 0.7))
	var win := {"type": "result", "winner": "attacker", "victory_type": "annihilation"}
	var fx := BattleConsequences.compute(win, _squad_of([["sergent_darmes", 2]]), _squad_of([["sergent_darmes", 4]]), "attacker")
	t.check("act2_xp_pacing", int(fx["xp"]) == 90 + 20 * 2, str(fx["xp"]))
	t.check("act2_liberation_reputation", _squad_of([["parfait", 10], ["trovador", 2]]).liberation_bonus() == 15
		and _squad_of([["routier", 9]]).liberation_bonus() == -8)
	await t.get_tree().process_frame


func _squad_of(specs: Array) -> SquadData:
	var squad := SquadData.new()
	for i: int in specs.size():
		squad.units.append(UnitInstance.create(_cls(specs[i][0]), "%s_%d" % [specs[i][0], i], specs[i][1], i, i == 0))
	return squad

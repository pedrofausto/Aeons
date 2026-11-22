extends RefCounted
## Classes míticas e encontros do Ato I (Act1_Mythic_Classes_Spec). Emite ACT1_MYTHIC_CLASSES_PASS.

const C := "res://eras/act_01_tianxu/classes/%s.tres"
const ENC := "res://eras/act_01_tianxu/encounters/%s.tres"
const ACT01 := "res://eras/act_01_tianxu/EraConfig_Act01.tres"


func run(t: Node) -> void:
	var failed_before: int = t.failed
	_reset()
	var cls: Dictionary = {}
	for id: String in ["jiangshi", "wu_sombrio", "huli_jing", "xian", "fangshi", "fubing", "daoshi_healer", "youxia"]:
		cls[id] = load(C % id) as UnitClassData
	t.check("mythic_classes_load", cls.values().all(func(c: UnitClassData) -> bool: return c != null))

	# 1. Todo class_id referenciado nas tabelas de encontro resolve sem null.
	var referenced: Array[String] = []
	var all_resolved: bool = true
	for table: Resource in WorldState.era_config.encounter_tables:
		for entry: EncounterEntry in (table as EncounterTable).entries:
			for unit: UnitInstance in entry.squad.units:
				all_resolved = all_resolved and unit.class_data != null
				if unit.class_data and unit.class_data.class_id not in referenced:
					referenced.append(unit.class_data.class_id)
	t.check("spawner_class_ids_resolve", all_resolved and ["jiangshi", "wu_sombrio", "huli_jing", "xian", "fangshi"].all(
		func(id: String) -> bool: return id in referenced), str(referenced))

	# 2. Resistências: físico comum contra Jiangshi = 20%; Espada de Jade (SPIRITUAL) = 150%.
	var state := SkillMath.new_state()
	var soldier := UnitInstance.create(cls["fubing"], "Soldado", 3, 0)
	var js := UnitInstance.create(cls["jiangshi"], "Jiangshi", 2, 0)
	var xian := UnitInstance.create(cls["xian"], "Xian", 4, 0)
	var dao: ActionSkillData = cls["fubing"].front_action
	var jade: ActionSkillData = cls["xian"].front_action
	var phys_base: int = SkillMath.base_damage(soldier, js, dao, 100, state).x
	var phys_hit: int = SkillMath.hit(soldier, js, dao, 100, state).x
	t.check("jiangshi_resists_physical_80", phys_hit == maxi(1, phys_base * 20 / 100) and phys_hit < phys_base,
		"%d de %d" % [phys_hit, phys_base])
	var jade_base: int = SkillMath.base_damage(xian, js, jade, 100, state).x
	var jade_hit: int = SkillMath.hit(xian, js, jade, 100, state).x
	t.check("xian_jade_sword_spiritual_150", jade.get_element() == "SPIRITUAL" and jade_hit == jade_base * 150 / 100,
		"%d de %d" % [jade_hit, jade_base])

	# 3. Imunidades e talismãs.
	var daoshi := UnitInstance.create(cls["daoshi_healer"], "Daoshi", 3, 0)
	var talisman: ActionSkillData = cls["daoshi_healer"].front_action
	var exorcism := SkillMath.hit(daoshi, js, talisman, 100, state)
	t.check("daoshi_talisman_exorcises_jiangshi", exorcism.x > 0 and exorcism.y == 0
		and SkillMath.hit(daoshi, soldier, talisman, 100, state).x == 0, str(exorcism))
	t.check("jiangshi_morale_immune", SkillMath.hit(soldier, js, dao, 100, state).y == 0)
	var fox := UnitInstance.create(cls["huli_jing"], "Raposa", 3, 3)
	var charm: ActionSkillData = cls["huli_jing"].back_action
	var charm_vs_xian := SkillMath.hit(fox, xian, charm, 100, state)
	var charm_base: int = SkillMath.base_damage(fox, xian, charm, 100, state).x
	t.check("xian_morale_drain_immune", charm_vs_xian.y == charm_base / 2
		and SkillMath.hit(daoshi, xian, talisman, 100, state).y == 0, str(charm_vs_xian))

	# 4. Status, buff e cura em área.
	t.check("huli_confuse_slow_target", SkillMath.try_inflict(fox, soldier, charm, state)
		and not SkillMath.try_inflict(fox, xian, charm, state)
		and SkillMath.consume_confusion(soldier, state) and not SkillMath.consume_confusion(soldier, state))
	var cortejo := (load(ENC % "squad_cortejo_de_jiangshi") as SquadData).clone()
	var bell: ActionSkillData = cls["wu_sombrio"].back_action
	SkillMath.apply_ally_buff(bell, cortejo, state)
	var buffs: Dictionary = state["buff"]
	t.check("wu_bell_buffs_jiangshi", int(buffs.get(cortejo.units[0].get_instance_id(), 0)) == 20
		and not buffs.has(cortejo.units[4].get_instance_id()))
	var sky := _squad([[cls["xian"], 4, 3, true]])
	var log_sky := CombatResolver.resolve(sky, _squad([[cls["fubing"], 1, 0, true]]))
	t.check("xian_harmony_bonus_strike", log_sky.any(func(e: Dictionary) -> bool:
		return e["type"] == "action" and e.get("element", "") == "SPIRITUAL" and int(e["damage"]) > 0))

	# 5. Cortejo em batalha real: dreno vital e regras pós-batalha.
	var guard := (WorldState.era_config.starting_squads[0] as SquadData).clone()
	var log_c := CombatResolver.resolve(guard, cortejo, TacticalOrder.Order.FOCUS_LEADER)
	t.check("jiangshi_vital_drain", log_c.any(func(e: Dictionary) -> bool: return int(e.get("drain", 0)) > 0))
	print("INFO|Guarda vs Cortejo de Jiangshi -> %s" % str(CombatResolver.get_result(log_c)))
	var win_hp := {"type": "result", "winner": "attacker", "victory_type": "annihilation"}
	var veterans := _squad([[cls["fubing"], 9, 0, true]])
	var fx_c := BattleConsequences.compute(win_hp, veterans, cortejo, "attacker")
	t.check("cortejo_no_level_penalty_plus_support", int(fx_c["alignment"]) == 0 and int(fx_c["popular_support"]) == 5
		and int(fx_c["drop_chance"]) == 25, str(fx_c))
	var drops: int = 0
	for day: int in 400:
		drops += 1 if BattleConsequences.rolls_drop(25, [1, day, "cortejo_de_jiangshi"]) else 0
	t.check("cortejo_rare_drop_25pct", drops > 70 and drops < 130
		and BattleConsequences.rolls_drop(25, [1, 7, "x"]) == BattleConsequences.rolls_drop(25, [1, 7, "x"]), "drops=%d/400" % drops)

	# 6. Chefe mítico de Pengming: Moral -> aliança + classe; Aniquilação -> bússola; rota de honra.
	var boss := (load(ENC % "squad_guardiao_xian_pengming") as SquadData).clone()
	var win_mor := {"type": "result", "winner": "attacker", "victory_type": "morale_break"}
	var with_room := (WorldState.era_config.starting_squads[0] as SquadData).clone()
	with_room.units.pop_back()  # 1 slot livre na grade para o rendido
	var report := BattleConsequences.apply(BattleConsequences.compute(win_mor, with_room, boss, "attacker"), with_room, boss)
	t.check("boss_morale_unlocks_xian", WorldState.has_flag("pengming_xian_ally") and "xian" in WorldState.unlocked_classes
		and report["recruited"] == "Xian do Orvalho", str(report))
	_reset()
	boss = (load(ENC % "squad_guardiao_xian_pengming") as SquadData).clone()
	BattleConsequences.apply(BattleConsequences.compute(win_hp, guard, boss, "attacker"), guard, boss)
	t.check("boss_annihilation_compass", WorldState.has_item("bussola_dos_nove_ceus")
		and is_equal_approx(WorldState.item_march_multiplier(), 1.2) and WorldState.reveals_night_encounters()
		and not WorldState.has_flag("pengming_xian_ally"))
	_reset()
	var honorable := _squad([[cls["youxia"], 5, 0, true]])
	honorable.units[0].alignment = 80
	var timeout_win := {"type": "result", "winner": "attacker", "victory_type": "timeout"}
	var flags := {"act1_blind_astronomer_protected": true}
	t.check("boss_honor_rule", BattleConsequences.compute(timeout_win, honorable, boss, "attacker", flags)["rewards"].has("unlock_class")
		and BattleConsequences.compute(timeout_win, honorable, boss, "attacker", {})["rewards"].is_empty())
	var pengming := load(ENC % "pengming_encounters") as EncounterTable
	var rng := RandomNumberGenerator.new()
	var before := pengming.pick(rng, "night", 5.0)
	WorldState.set_flag("defeated_guardiao_xian_pengming")
	t.check("boss_reactivable_until_defeated", before != null and pengming.pick(rng, "day", 5.0) == null)

	# 7. Mapa: Jiangshi lento de dia e rápido à noite; Xian voa; emboscada noturna oculta.
	t.check("jiangshi_night_march", is_equal_approx(_squad([[cls["jiangshi"], 1, 0, true]]).march_factor("day"), 0.6)
		and is_equal_approx(_squad([[cls["jiangshi"], 1, 0, true]]).march_factor("night"), 1.1)
		and cls["xian"].movement == "flying")
	_reset()
	var token := SquadToken.new()
	token.squad = cortejo
	cortejo.roaming_until_day = true
	token._process(0.0)
	var hidden: bool = not token.visible
	WorldState.add_item(load("res://eras/act_01_tianxu/items/bussola_dos_nove_ceus.tres"))
	token._process(0.0)
	t.check("night_encounter_hidden_without_compass", hidden and token.visible)
	token.free()
	_reset()

	if t.failed == failed_before:
		print("ACT1_MYTHIC_CLASSES_PASS")


func _reset() -> void:
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)


func _squad(specs: Array) -> SquadData:
	var squad := SquadData.new()
	squad.faction = "player"
	for spec: Array in specs:
		squad.units.append(UnitInstance.create(spec[0], "u%d" % squad.units.size(), spec[1], spec[2], spec[3]))
	return squad

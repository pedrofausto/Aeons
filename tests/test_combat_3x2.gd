extends RefCounted
## Testes de combate 3x2: vitória por HP, vitória por Moral, determinismo e ordens.

const FUBING := "res://eras/act_01_tianxu/classes/fubing.tres"
const JI := "res://eras/act_01_tianxu/classes/ji_halberdier.tres"
const NUBING := "res://eras/act_01_tianxu/classes/nubing_crossbow.tres"
const DAOSHI := "res://eras/act_01_tianxu/classes/daoshi_healer.tres"


func run(t: Node) -> void:
	var fubing := load(FUBING) as UnitClassData
	var ji := load(JI) as UnitClassData
	var nubing := load(NUBING) as UnitClassData
	var daoshi := load(DAOSHI) as UnitClassData
	t.check("act01_classes_load", fubing != null and ji != null and nubing != null and daoshi != null)
	t.check("act01_archetypes", fubing.archetype == UnitClassData.Archetype.VANGUARD
		and ji.archetype == UnitClassData.Archetype.SHOCK
		and nubing.archetype == UnitClassData.Archetype.RANGED_STEALTH
		and daoshi.archetype == UnitClassData.Archetype.HEALER_MORAL)

	# Promoção honrada: Fubing -> Youxia exige nível 4 e alinhamento >= 65
	var youxia := load("res://eras/act_01_tianxu/classes/youxia.tres") as UnitClassData
	var low := UnitInstance.create(fubing, "Baixo", 4, 0, false, 50)
	var high := UnitInstance.create(fubing, "Alto", 4, 1, false, 70)
	var young := UnitInstance.create(fubing, "Novo", 2, 2, false, 90)
	var promo_squad := SquadData.new()
	promo_squad.units.append_array([low, high, young])
	t.check("promotion_requirements", low.get_eligible_promotions().is_empty() and young.get_eligible_promotions().is_empty()
		and high.get_eligible_promotions() == [youxia])
	var promoted := promo_squad.promote_eligible()
	t.check("promotion_fubing_to_youxia", promoted.size() == 1 and high.class_data == youxia
		and high.hp == high.get_max_hp() and low.class_data == fubing, str(promoted))
	var buqu := load("res://eras/act_01_tianxu/classes/buqu.tres") as UnitClassData
	var brute := UnitInstance.create(fubing, "Brutal", 4, 3, false, 20)
	t.check("promotion_fubing_to_buqu_evil", brute.get_eligible_promotions() == [buqu] and brute.promote(buqu)
		and brute.class_data == buqu)
	t.check("class_preferred_doctrine", youxia.matches_doctrine(-40) and not youxia.matches_doctrine(30)
		and buqu.matches_doctrine(30) and fubing.matches_doctrine(99))

	var probe := UnitInstance.create(fubing, "Sonda", 1, 4)
	t.check("grid_slot_rows", probe.get_row() == 1 and probe.get_column() == 1 and probe.get_action() == fubing.back_action)

	# Vitória por HP (Aniquilação)
	var strong := _squad("player", [[fubing, 8, 0, true], [ji, 8, 1, false], [nubing, 8, 3, false]])
	var weak := _squad("enemy", [[fubing, 1, 1, true], [nubing, 1, 4, false]])
	var log_hp := CombatResolver.resolve(strong, weak, TacticalOrder.Order.NONE)
	var res_hp := CombatResolver.get_result(log_hp)
	t.check("combat_victory_by_hp", res_hp.get("winner") == "attacker" and res_hp.get("victory_type") == "annihilation",
		str(res_hp))

	# Vitória por Moral (Rendição): ordem Poupar/Render + Daoshi na frente
	var pacifists := _squad("player", [[daoshi, 6, 0, false], [daoshi, 6, 1, true], [daoshi, 6, 2, false], [fubing, 6, 4, false]])
	var garrison := _squad("enemy", [[fubing, 2, 0, true], [fubing, 2, 1, false], [nubing, 2, 4, false]])
	var log_mor := CombatResolver.resolve(pacifists, garrison, TacticalOrder.Order.SPARE)
	var res_mor := CombatResolver.get_result(log_mor)
	t.check("combat_victory_by_morale", res_mor.get("winner") == "attacker" and res_mor.get("victory_type") == "morale_break",
		str(res_mor))
	t.check("morale_victory_spares_lives", garrison.get_living_units().size() == garrison.units.size(),
		"vivos=%d" % garrison.get_living_units().size())

	# Determinismo: mesmas entradas => mesmo log
	var a1 := _squad("player", [[fubing, 3, 1, true], [ji, 2, 0, false], [daoshi, 2, 5, false]])
	var b1 := _squad("enemy", [[fubing, 3, 1, true], [nubing, 2, 3, false], [nubing, 2, 4, false]])
	var log1 := CombatResolver.resolve(a1.clone(), b1.clone(), TacticalOrder.Order.FOCUS_WEAK)
	var log2 := CombatResolver.resolve(a1.clone(), b1.clone(), TacticalOrder.Order.FOCUS_WEAK)
	t.check("combat_deterministic", JSON.stringify(log1) == JSON.stringify(log2))

	# Ordem de turno por agility (Nubing 13 > Ji 11 > Fubing 9)
	var first_action: Dictionary = _first_of(log1, "action")
	var first_actor: UnitInstance = (b1 if first_action["actor_side"] == "defender" else a1).units[first_action["actor_index"]]
	t.check("turn_order_by_agility", first_actor.class_data == nubing, str(first_action))

	# Focar Líder: o primeiro golpe ofensivo do jogador mira o líder inimigo
	var a2 := _squad("player", [[fubing, 3, 0, true]])
	var b2 := _squad("enemy", [[fubing, 1, 0, false], [fubing, 1, 1, false], [nubing, 1, 5, true]])
	var log3 := CombatResolver.resolve(a2, b2, TacticalOrder.Order.FOCUS_LEADER)
	var hit: Dictionary = _first_of(log3, "action", "attacker")
	t.check("order_focus_leader", int(hit.get("target_index", -1)) == 2, str(hit))

	# Queda do líder derruba a moral dos aliados
	t.check("leader_fall_morale", _has_event(log_hp, "leader_fallen"))

	# Fadiga reduz o dano físico
	var rested := _squad("player", [[fubing, 3, 0, true]])
	var tired := _squad("player", [[fubing, 3, 0, true]])
	tired.fatigue = 100
	var dmg_rested: int = int(_first_of(CombatResolver.resolve(rested, _squad("enemy", [[fubing, 3, 0, true]])), "action", "attacker")["damage"])
	var dmg_tired: int = int(_first_of(CombatResolver.resolve(tired, _squad("enemy", [[fubing, 3, 0, true]])), "action", "attacker")["damage"])
	t.check("fatigue_reduces_damage", dmg_tired < dmg_rested, "%d vs %d" % [dmg_tired, dmg_rested])

	# Consequências: Aniquilação -> Revolucionária; Rendição -> Pacifista + Apoio
	var fx_hp := BattleConsequences.compute(res_hp, strong, weak, "attacker")
	var fx_mor := BattleConsequences.compute(res_mor, pacifists, garrison, "attacker")
	t.check("consequence_annihilation_revolutionary", int(fx_hp["doctrine"]) > 0 and int(fx_hp["alignment"]) < 0, str(fx_hp))
	t.check("consequence_surrender_pacifist", int(fx_mor["doctrine"]) < 0 and int(fx_mor["popular_support"]) > 0, str(fx_mor))

	# Tags de encontro (diff §5) e recrutamento na Rendição por Moral (diff §3)
	var win_hp := {"type": "result", "winner": "attacker", "victory_type": "annihilation"}
	var win_mor := {"type": "result", "winner": "attacker", "victory_type": "morale_break"}
	var mid := _squad("player", [[fubing, 3, 0, true]])
	var bandits := _squad("enemy", [[fubing, 3, 0, true]])
	bandits.encounter_tag = "bandit_loot"
	t.check("tag_bandit_loot", int(BattleConsequences.compute(win_hp, mid, bandits, "attacker")["resources"]) == 180)
	var wolves := _squad("enemy", [[fubing, 3, 0, true]])
	wolves.encounter_tag = "natural_wildlife"
	var fx_wild := BattleConsequences.compute(win_hp, mid, wolves, "attacker")
	t.check("tag_natural_wildlife_neutral", fx_wild["alignment"] == 0 and fx_wild["doctrine"] == 0 and not fx_wild["recruit"])
	var trap := _squad("enemy", [[ji, 1, 0, false], [daoshi, 1, 4, true]])
	trap.encounter_tag = "low_level_trap"
	var veterans := _squad("player", [[fubing, 6, 0, true]])
	t.check("tag_low_level_trap", int(BattleConsequences.compute(win_hp, veterans, trap, "attacker")["alignment"]) == -13
		and int(BattleConsequences.compute(win_mor, veterans, trap, "attacker")["alignment"]) == 0)
	var fx_rec := BattleConsequences.compute(win_mor, veterans, trap, "attacker")
	var recruited := BattleConsequences.recruit_surrendered(veterans, trap)
	t.check("morale_victory_recruits", fx_rec["recruit"] and recruited == "enemy_0" and veterans.units.size() == 2
		and veterans.units[1].slot == 1 and trap.units.size() == 1, recruited)
	var full := _squad("player", [[fubing, 3, 0, true], [fubing, 3, 1, false], [fubing, 3, 2, false],
		[nubing, 3, 3, false], [nubing, 3, 4, false], [daoshi, 3, 5, false]])
	t.check("morale_victory_frees_when_full", BattleConsequences.recruit_surrendered(full, _squad("enemy", [[ji, 1, 0, false]])) == ""
		and full.units.size() == 6)

	_test_pending_skills(t)

	# Combate real do Ato I resolve sem erros
	var era := load("res://eras/act_01_tianxu/EraConfig_Act01.tres") as EraConfig
	var ally := era.starting_squads[0].clone()
	var fort := (era.map_nodes[3] as MapNodeData).garrison.clone()
	var real := CombatResolver.get_result(CombatResolver.resolve(ally, fort, TacticalOrder.Order.FOCUS_LEADER))
	t.check("act01_real_battle_resolves", real.get("type") == "result", str(real))
	print("INFO|act01 Guarda vs Guarnição (Focar Líder) -> %s" % str(real))


func _squad(faction: String, specs: Array) -> SquadData:
	var squad := SquadData.new()
	squad.squad_id = faction
	squad.display_name = faction
	squad.faction = faction
	var n: int = 0
	for spec: Array in specs:
		squad.units.append(UnitInstance.create(spec[0], "%s_%d" % [faction, n], spec[1], spec[2], spec[3]))
		n += 1
	return squad


func _first_of(log: Array[Dictionary], type: String, side: String = "") -> Dictionary:
	for event: Dictionary in log:
		if event["type"] == type and (side.is_empty() or event.get("actor_side", "") == side):
			return event
	return {}


func _has_event(log: Array[Dictionary], type: String) -> bool:
	return not _first_of(log, type).is_empty()


const A2 := "res://eras/act_02_occitania/classes/%s.tres"


## Spec_Pendencias §3: saque por acerto, veneno contínuo e bônus de terreno.
func _test_pending_skills(t: Node) -> void:
	var routier := load(A2 % "routier") as UnitClassData
	var sergent := load(A2 % "sergent_darmes") as UnitClassData
	var raiders := SquadData.new()
	raiders.units.append(UnitInstance.create(routier, "Saqueador", 9, 3, true))
	var plain := SquadData.new()
	plain.units.append(UnitInstance.create(sergent, "Soldado", 9, 3, true))
	var dummy := func() -> SquadData:
		var s := SquadData.new()
		s.units.append(UnitInstance.create(sergent, "Alvo", 9, 0, true))
		return s
	var log_loot := CombatResolver.resolve(raiders, dummy.call())
	var hits: int = log_loot.filter(func(e: Dictionary) -> bool:
		return e["type"] == "action" and e["actor_side"] == "attacker" and int(e["damage"]) > 0).size()
	var loot: int = int(CombatResolver.get_result(log_loot)["bonus_resources"]["attacker"])
	var log_none := CombatResolver.resolve(plain, dummy.call())
	t.check("skill_resources_on_hit", routier.back_action.resources_on_hit == 12 and hits > 0 and loot == 12 * hits
		and int(CombatResolver.get_result(log_none)["bonus_resources"]["attacker"]) == 0, "saque=%d acertos=%d" % [loot, hits])
	var win := CombatResolver.get_result(log_loot).duplicate()
	win["winner"] = "attacker"
	win["victory_type"] = "annihilation"
	var fx := BattleConsequences.compute(win, raiders, dummy.call(), "attacker")
	t.check("skill_loot_reaches_resources", int(fx["resources"]) == BattleConsequences.LOOT_ON_VICTORY + loot)

	var sicario := load(A2 % "sicario_inquisitorial") as UnitClassData
	var assassin := UnitInstance.create(sicario, "Sicário", 10, 3, true)
	var bolt: ActionSkillData = sicario.back_action
	var state := SkillMath.new_state()
	var slow := UnitInstance.create(sergent, "Lento", 5, 0)
	var fast := UnitInstance.create(sicario, "Rápido", 12, 0)
	var beast := UnitInstance.create(load(A2 % "tarasca"), "Fera", 6, 1)
	var applied: bool = SkillMath.try_inflict(assassin, slow, bolt, state)
	var max_hp: int = slow.get_max_hp()
	var hp0: int = slow.hp
	var tick1: int = SkillMath.tick_poison(slow, state)
	var tick2: int = SkillMath.tick_poison(slow, state)
	var tick3: int = SkillMath.tick_poison(slow, state)
	t.check("skill_poison_two_rounds_10pct", applied and tick1 == max_hp / 10 and tick2 == max_hp / 10 and tick3 == 0
		and slow.hp == hp0 - 2 * (max_hp / 10))
	var fast_full: bool = SkillMath.try_inflict(assassin, fast, bolt, state)
	fast.hp = fast.get_max_hp() / 2
	t.check("skill_poison_rule_and_immunity", not fast_full and SkillMath.try_inflict(assassin, fast, bolt, state)
		and not SkillMath.try_inflict(assassin, beast, bolt, state))
	var poisoned := SquadData.new()
	poisoned.units.append(assassin)
	var log_poison := CombatResolver.resolve(poisoned, dummy.call())
	t.check("skill_poison_ticks_in_battle", log_poison.any(func(e: Dictionary) -> bool: return e["type"] == "poison"))

	var faydit := load(A2 % "faydit") as UnitClassData
	var knight := UnitInstance.create(faydit, "Faydit", 10, 0, true, 70)
	var foe := UnitInstance.create(sergent, "Alvo", 10, 0)
	var cut: ActionSkillData = faydit.front_action
	var on_plains: int = SkillMath.base_damage(knight, foe, cut, 100, SkillMath.new_state("plains")).x
	var on_mountain: int = SkillMath.base_damage(knight, foe, cut, 100, SkillMath.new_state("mountain")).x
	var expected: int = knight.get_attack() * (cut.power * 125 / 100) / 100 - foe.get_defense() * (100 - cut.armor_pierce_pct) / 200
	t.check("skill_faydit_mountain_bonus", cut.bonus_terrain == "mountain" and cut.bonus_terrain_power_pct == 25
		and on_mountain > on_plains and on_mountain == expected, "%d vs %d" % [on_plains, on_mountain])

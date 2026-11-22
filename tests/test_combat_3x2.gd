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

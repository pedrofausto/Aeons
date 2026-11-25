class_name TurnBattleSession
extends RefCounted
## Sessão de combate por turnos (3x2) com escolha de ação e alvo por personagem.
## Reutiliza SkillMath, CombatTargeting, TacticalOrder e CombatResolver sem duplicar fórmulas.

const MAX_MANUAL_ROUNDS: int = 6

var squads: Dictionary = {}
var player_side: String = "attacker"
var state: Dictionary = {}
var orders: Dictionary = {"attacker": TacticalOrder.Order.NONE, "defender": TacticalOrder.Order.NONE}
var turn_order: Array[Dictionary] = []
var round_index: int = 1
var cursor: int = 0
var round_started: bool = false
var current_actor_ref: Dictionary = {}
var result: Dictionary = {}


func setup(p_attacker: SquadData, p_defender: SquadData, p_player_side: String = "attacker",
		p_context: Dictionary = {}) -> void:
	squads = {"attacker": p_attacker, "defender": p_defender}
	player_side = p_player_side
	state = SkillMath.new_state(String(p_context.get("terrain", "")))
	state["orders"] = orders
	for squad: SquadData in [p_attacker, p_defender]:
		for unit: UnitInstance in squad.units:
			unit.ensure_vitals()
	turn_order = CombatResolver._build_turn_order(p_attacker, p_defender)
	round_index = 1
	cursor = 0
	round_started = false
	current_actor_ref = {}
	result = {}


func is_finished() -> bool:
	return not result.is_empty()


func get_result() -> Dictionary:
	return result


func get_current_actor() -> UnitInstance:
	if current_actor_ref.is_empty():
		return null
	return (squads[current_actor_ref["side"]] as SquadData).units[int(current_actor_ref["index"])]


func get_current_actor_index() -> int:
	return int(current_actor_ref.get("index", -1))


## Lista as ações disponíveis para `unit`: golpe da fileira atual, golpe secundário, Poupar/Moral e Defender.
func get_available_actions(unit: UnitInstance) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if unit == null or unit.class_data == null:
		return actions
	var primary: ActionSkillData = unit.get_action()
	var secondary: ActionSkillData = unit.class_data.back_action if unit.get_row() == 0 else unit.class_data.front_action
	if primary != null:
		actions.append({"kind": "skill", "label": primary.display_name, "skill": primary,
			"order": TacticalOrder.Order.NONE, "needs_target": _needs_enemy_target(primary)})
	if secondary != null and secondary != primary:
		actions.append({"kind": "skill", "label": secondary.display_name, "skill": secondary,
			"order": TacticalOrder.Order.NONE, "needs_target": _needs_enemy_target(secondary)})
	if primary != null and primary.effect != ActionSkillData.Effect.HEAL and primary.effect != ActionSkillData.Effect.BUFF:
		actions.append({"kind": "skill", "label": "Poupar (%s)" % primary.display_name, "skill": primary,
			"order": TacticalOrder.Order.SPARE, "needs_target": _needs_enemy_target(primary)})
	actions.append({"kind": "defend", "label": "Defender", "skill": null,
		"order": TacticalOrder.Order.DEFEND, "needs_target": false})
	return actions


## Avança turnos automáticos (inimigos, confusos, fim de rodada) até o próximo turno do jogador ou fim da batalha.
func advance_until_player_turn() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	current_actor_ref = {}
	while not is_finished():
		if round_index > MAX_MANUAL_ROUNDS:
			_set_finished(events, CombatResolver._timeout_result(squads["attacker"], squads["defender"]))
			return events
		if not round_started:
			orders[player_side] = TacticalOrder.Order.NONE
			events.append({"type": "round_start", "round": round_index})
			round_started = true
		if cursor >= turn_order.size():
			CombatResolver._tick_poison(squads, state, events)
			if _check_and_finish(events):
				return events
			round_index += 1
			cursor = 0
			round_started = false
			continue
		var actor_ref: Dictionary = turn_order[cursor]
		cursor += 1
		var side: String = actor_ref["side"]
		var actor: UnitInstance = (squads[side] as SquadData).units[int(actor_ref["index"])]
		if not actor.can_act():
			continue
		if SkillMath.consume_confusion(actor, state):
			events.append({"type": "confused", "side": side, "index": actor_ref["index"]})
			continue
		if side == player_side:
			current_actor_ref = actor_ref
			return events
		CombatResolver._perform_action(actor, actor_ref, squads[side], squads[CombatResolver._other(side)], orders[side], state, events)
		if _check_and_finish(events):
			return events
	return events


## Executa a ação escolhida pelo jogador (com `target_index` opcional para alvos únicos).
func execute_player_action(action_index: int, target_index: int = -1) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var actor: UnitInstance = get_current_actor()
	if actor == null or is_finished():
		return events
	var actions := get_available_actions(actor)
	if action_index < 0 or action_index >= actions.size():
		action_index = 0
	var act: Dictionary = actions[action_index]
	var own: SquadData = squads[player_side]
	var foes: SquadData = squads[CombatResolver._other(player_side)]
	if String(act["kind"]) == "defend":
		orders[player_side] = TacticalOrder.Order.DEFEND
		actor.morale = mini(actor.morale + 10, actor.get_max_morale())
		events.append({"type": "action", "actor_side": player_side, "actor_index": get_current_actor_index(),
			"skill": "Defender", "target_side": player_side, "target_index": get_current_actor_index(),
			"damage": 0, "morale_damage": 0, "heal": 0, "target_hp": actor.hp, "target_morale": actor.morale})
	else:
		var skill: ActionSkillData = act["skill"]
		var order: TacticalOrder.Order = act["order"] as TacticalOrder.Order
		_execute_skill(actor, current_actor_ref, skill, own, foes, order, target_index, events)
	current_actor_ref = {}
	_check_and_finish(events)
	return events


func _execute_skill(actor: UnitInstance, actor_ref: Dictionary, skill: ActionSkillData, own: SquadData,
		foes: SquadData, order: TacticalOrder.Order, target_index: int, events: Array[Dictionary]) -> void:
	if skill.effect == ActionSkillData.Effect.HEAL:
		CombatResolver._heal(actor, actor_ref, skill, own, foes, state, events)
		SkillMath.apply_ally_buff(skill, own, state)
		return
	if skill.effect == ActionSkillData.Effect.BUFF:
		events.append({"type": "buff", "side": actor_ref["side"], "index": actor_ref["index"], "skill": skill.display_name})
		SkillMath.apply_ally_buff(skill, own, state)
		CombatResolver._drain_all(foes, skill.enemy_morale_drain, CombatResolver._other(actor_ref["side"]), events)
		return
	for _hit: int in skill.hits:
		var targets: Array[int] = []
		if _needs_enemy_target(skill) and target_index >= 0 \
				and target_index < foes.units.size() and foes.units[target_index].is_alive():
			targets.append(target_index)
		else:
			targets = CombatTargeting.pick_targets(skill, foes, order)
		for tidx: int in targets:
			CombatResolver._strike(actor, actor_ref, skill, own, foes, tidx, order, state, events)
	SkillMath.apply_ally_buff(skill, own, state)


func _needs_enemy_target(skill: ActionSkillData) -> bool:
	return skill != null and skill.effect != ActionSkillData.Effect.HEAL \
		and skill.effect != ActionSkillData.Effect.BUFF \
		and skill.targeting != ActionSkillData.Targeting.ALL_ENEMIES


func _check_and_finish(events: Array[Dictionary]) -> bool:
	var ending := CombatResolver._check_end(squads["attacker"], squads["defender"], round_index)
	if ending.is_empty():
		return false
	_set_finished(events, ending)
	return true


func _set_finished(events: Array[Dictionary], ending: Dictionary) -> void:
	ending["bonus_resources"] = (state["loot"] as Dictionary).duplicate()
	ending["rounds"] = mini(round_index, MAX_MANUAL_ROUNDS)
	events.append(ending)
	result = ending

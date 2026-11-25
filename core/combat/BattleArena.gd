class_name BattleArena
extends Node2D
## Cena isolada 3x2: combate por turnos com escolha de golpe/alvo por personagem (ou modo automático).

signal closed(result: Dictionary)

const ALLY_ROW_X: Array[float] = [235.0, 160.0]
const ENEMY_ROW_X: Array[float] = [405.0, 480.0]
const COLUMN_Y: Array[float] = [115.0, 175.0, 235.0]

@export var step_seconds: float = 0.25
@export var autoplay_order: int = -1                 # >= 0: inicia automático (testes)

var ally_squad: SquadData
var enemy_squad: SquadData
var context: Dictionary = {}
var battle_log: Array[Dictionary] = []
var result: Dictionary = {}
var turn_session: TurnBattleSession
var _cards: Dictionary = {}
var _selected_action_idx: int = -1
var _turn_busy: bool = false

@onready var _header: Label = %Header
@onready var _orders_box: HBoxContainer = %OrdersBox
@onready var _status: Label = %Status
@onready var _result_panel: PanelContainer = %ResultPanel
@onready var _result_label: Label = %ResultLabel
@onready var _continue_button: Button = %ContinueButton
@onready var _units_root: Node2D = %Units

func setup(p_ally: SquadData, p_enemy: SquadData, p_context: Dictionary = {}) -> void:
	ally_squad = p_ally
	enemy_squad = p_enemy
	context = p_context
func _ready() -> void:
	if ally_squad == null:
		_load_demo_squads()
	_result_panel.hide()
	_continue_button.pressed.connect(func() -> void: closed.emit(result))
	var era: EraConfig = WorldState.era_config
	if era:
		(%UIRoot as Control).theme = era.ui_theme
	%Background.color = era.color_background if era else Color(0.08, 0.08, 0.08)
	var backdrop_art: TextureRect = %BackdropArt
	var loc_tex: Texture2D = TurnBattleSession.resolve_location_backdrop(era, context)
	backdrop_art.texture = loc_tex if loc_tex != null else (era.battle_backdrop if era else null)
	backdrop_art.visible = backdrop_art.texture != null
	_header.text = "%s  ×  %s" % [ally_squad.display_name, enemy_squad.display_name]
	_build_cards()
	if autoplay_order >= 0:
		_build_order_buttons(era)
		start_battle.call_deferred(autoplay_order as TacticalOrder.Order)
	else:
		_begin_turn_mode.call_deferred()
	if OS.is_debug_build():
		print("TEST_PASS|battle_arena_boot")

func get_player_side() -> String:
	return String(context.get("player_side", "attacker"))
func _begin_turn_mode() -> void:
	turn_session = TurnBattleSession.new()
	var attacker: SquadData = ally_squad if get_player_side() == "attacker" else enemy_squad
	turn_session.setup(attacker, enemy_squad if attacker == ally_squad else ally_squad, get_player_side(), context)
	await _advance_turn_loop()

func _advance_turn_loop() -> void:
	_turn_busy = true
	_set_highlights(false, false)
	_clear_action_buttons()
	await _play_events(turn_session.advance_until_player_turn())
	_sync_all_cards()
	if turn_session.is_finished():
		_finish_with_result(turn_session.get_result(), TacticalOrder.Order.NONE)
		_turn_busy = false
		return
	_turn_busy = false
	_selected_action_idx = -1
	var actor: UnitInstance = turn_session.get_current_actor()
	var card := _cards.get("%s:%d" % [get_player_side(), turn_session.get_current_actor_index()]) as UnitCardView
	if card != null:
		card.active_turn = true
	_status.text = "Turno de %s (%s) — escolha uma ação" % [actor.unit_name, actor.class_data.display_name]
	_populate_turn_buttons(actor)

func _populate_turn_buttons(actor: UnitInstance) -> void:
	var actions := turn_session.get_available_actions(actor)
	for i: int in actions.size():
		var act: Dictionary = actions[i]
		var btn := Button.new()
		btn.text = String(act["label"])
		btn.custom_minimum_size = Vector2(78, 24)
		btn.pressed.connect(_on_action_pressed.bind(i, act))
		_orders_box.add_child(btn)
	var auto_btn := Button.new()
	auto_btn.text = "⚡ Auto"
	auto_btn.custom_minimum_size = Vector2(56, 24)
	auto_btn.pressed.connect(func() -> void: start_battle(TacticalOrder.Order.NONE))
	_orders_box.add_child(auto_btn)

func _on_action_pressed(action_idx: int, act: Dictionary) -> void:
	if _turn_busy or turn_session == null or turn_session.is_finished():
		return
	if bool(act["needs_target"]) and _selected_action_idx != action_idx:
		_selected_action_idx = action_idx
		_set_highlights(false, true)
		_status.text = "Clique em um inimigo para usar %s (ou clique de novo)" % String(act["label"])
		return
	await _run_player_action(action_idx, -1)

func _run_player_action(action_idx: int, target_idx: int) -> void:
	_turn_busy = true
	_set_highlights(false, false)
	_clear_action_buttons()
	await _play_events(turn_session.execute_player_action(action_idx, target_idx))
	_sync_all_cards()
	if turn_session.is_finished():
		_finish_with_result(turn_session.get_result(), TacticalOrder.Order.NONE)
		_turn_busy = false
		return
	await _advance_turn_loop()

func _unhandled_input(event: InputEvent) -> void:
	if _turn_busy or turn_session == null or turn_session.is_finished() or turn_session.get_current_actor() == null:
		return
	var screen_pos: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		screen_pos = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		screen_pos = (event as InputEventScreenTouch).position
	else:
		return
	var world_pos: Vector2 = get_canvas_transform().affine_inverse() * screen_pos
	var foe_side: String = CombatResolver._other(get_player_side())
	for i: int in enemy_squad.units.size():
		var card := _cards.get("%s:%d" % [foe_side, i]) as UnitCardView
		if card != null and enemy_squad.units[i].is_alive() and card.contains_point(world_pos):
			get_viewport().set_input_as_handled()
			_run_player_action(_selected_action_idx if _selected_action_idx >= 0 else 0, i)
			return

func start_battle(order: TacticalOrder.Order) -> void:
	_turn_busy = true
	_set_highlights(false, false)
	_clear_action_buttons()
	var attacker: SquadData = ally_squad if get_player_side() == "attacker" else enemy_squad
	var defender: SquadData = enemy_squad if attacker == ally_squad else ally_squad
	battle_log = CombatResolver.resolve(attacker, defender,
		order if attacker == ally_squad else TacticalOrder.Order.NONE,
		order if defender == ally_squad else TacticalOrder.Order.NONE, context)
	await _play_events(battle_log)
	_finish_with_result(CombatResolver.get_result(battle_log), order)
	_turn_busy = false

func _finish_with_result(raw_result: Dictionary, order: TacticalOrder.Order) -> void:
	result = raw_result.duplicate()
	result["order"] = order
	result["context"] = context
	result["effects"] = BattleConsequences.compute(result, ally_squad, enemy_squad, get_player_side(),
		WorldState.active_flags.merged(EssenceState.decisions))
	var era: EraConfig = WorldState.era_config
	var won: bool = bool((result["effects"] as Dictionary)["player_won"])
	_result_label.text = "%s — %s" % [
		era.get_outcome_label("victory" if won else "defeat") if era else ("Vitória" if won else "Derrota"),
		era.get_outcome_label(String(result["victory_type"])) if era else String(result["victory_type"])]
	_result_panel.show()
	print("BATTLE_RESULT|%s|%s|rounds=%d" % [result["winner"], result["victory_type"], result["rounds"]])
	EventBus.battle_ended.emit(result)

func _play_events(events: Array[Dictionary]) -> void:
	for event: Dictionary in events:
		match String(event["type"]):
			"round_start": _status.text = "Rodada %d" % int(event["round"])
			"action":
				var card := _cards.get("%s:%d" % [event["target_side"], event["target_index"]]) as UnitCardView
				if card:
					card.show_values(int(event["target_hp"]), int(event["target_morale"]))
				_status.text = TurnBattleSession.describe_action(event,
					_squad_for(String(event["actor_side"])).units[int(event["actor_index"])],
					_squad_for(String(event["target_side"])).units[int(event["target_index"])], WorldState.era_config)
			"leader_fallen": _status.text = "O líder caiu!"
			_: continue
		if step_seconds > 0.0:
			await get_tree().create_timer(step_seconds).timeout

func _squad_for(side: String) -> SquadData:
	return ally_squad if (side == "attacker") == (get_player_side() == "attacker") else enemy_squad
func _build_cards() -> void:
	var era: EraConfig = WorldState.era_config
	for side: String in ["attacker", "defender"]:
		var squad := _squad_for(side)
		var is_ally: bool = squad == ally_squad
		var rows: Array[float] = ALLY_ROW_X if is_ally else ENEMY_ROW_X
		var color: Color = era.color_for_faction(squad.faction) if era else Color.WHITE
		for i: int in squad.units.size():
			var unit: UnitInstance = squad.units[i]
			unit.ensure_vitals()
			var card := UnitCardView.new()
			var x: float = (rows[0] + rows[1]) / 2.0 if unit.class_data.grid_slots >= 2 else rows[unit.get_row()]
			card.position = Vector2(x, COLUMN_Y[unit.get_column()])
			_units_root.add_child(card)
			card.setup(unit, color, not is_ally)
			_cards["%s:%d" % [side, i]] = card

func _sync_all_cards() -> void:
	for side: String in ["attacker", "defender"]:
		var squad := _squad_for(side)
		for i: int in squad.units.size():
			var card := _cards.get("%s:%d" % [side, i]) as UnitCardView
			if card != null:
				card._hp = squad.units[i].hp
				card._morale = squad.units[i].morale
				card.queue_redraw()

func _set_highlights(keep_active: bool, mark_enemies: bool) -> void:
	for card: UnitCardView in _cards.values():
		if not keep_active:
			card.active_turn = false
		card.target_highlighted = false
	if mark_enemies:
		var foe_side: String = CombatResolver._other(get_player_side())
		for i: int in enemy_squad.units.size():
			var card := _cards.get("%s:%d" % [foe_side, i]) as UnitCardView
			if card != null:
				card.target_highlighted = enemy_squad.units[i].is_alive()

func _clear_action_buttons() -> void:
	for child: Node in _orders_box.get_children():
		_orders_box.remove_child(child)
		child.queue_free()
func _build_order_buttons(era: EraConfig) -> void:
	for order: int in [TacticalOrder.Order.FOCUS_LEADER, TacticalOrder.Order.FOCUS_WEAK,
			TacticalOrder.Order.SPARE, TacticalOrder.Order.DEFEND]:
		var button := Button.new()
		button.text = era.get_order_label(order) if era else str(order)
		button.custom_minimum_size = Vector2(90, 26)
		button.pressed.connect(start_battle.bind(order))
		_orders_box.add_child(button)

func _load_demo_squads() -> void:
	var era: EraConfig = WorldState.era_config
	ally_squad = era.starting_squads[0].clone()
	for node_data: MapNodeData in era.map_nodes:
		if node_data.garrison:
			enemy_squad = node_data.garrison.clone()
			context = {"node_id": node_data.node_id, "player_side": "attacker"}
			return

class_name BattleArena
extends Node2D
## Cena isolada 3x2: recebe (ally_squad, enemy_squad), deixa o jogador escolher uma
## ordem tática, resolve via CombatResolver (lógica pura) e reproduz o battle_log.

signal closed(result: Dictionary)

const ALLY_ROW_X: Array[float] = [235.0, 160.0]     # frente, trás (resolução lógica 640x360)
const ENEMY_ROW_X: Array[float] = [405.0, 480.0]
const COLUMN_Y: Array[float] = [115.0, 175.0, 235.0]

@export var step_seconds: float = 0.25
@export var autoplay_order: int = -1                 # >= 0: inicia sozinho (testes/demonstração)

var ally_squad: SquadData
var enemy_squad: SquadData
var context: Dictionary = {}                          # { node_id, player_side }
var battle_log: Array[Dictionary] = []
var result: Dictionary = {}
var _cards: Dictionary = {}                           # "attacker:3" -> UnitCardView

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
	_continue_button.pressed.connect(_on_continue)
	var era: EraConfig = WorldState.era_config
	if era:
		(%UIRoot as Control).theme = era.ui_theme
	%Background.color = era.color_background if era else Color(0.08, 0.08, 0.08)
	_header.text = "%s  ×  %s" % [ally_squad.display_name, enemy_squad.display_name]
	_build_cards()
	_build_order_buttons(era)
	if autoplay_order >= 0:
		start_battle.call_deferred(autoplay_order as TacticalOrder.Order)
	if OS.is_debug_build():
		print("TEST_PASS|battle_arena_boot")


func get_player_side() -> String:
	return String(context.get("player_side", "attacker"))


func start_battle(order: TacticalOrder.Order) -> void:
	for button: Node in _orders_box.get_children():
		(button as Button).disabled = true
	var attacker: SquadData = ally_squad if get_player_side() == "attacker" else enemy_squad
	var defender: SquadData = enemy_squad if attacker == ally_squad else ally_squad
	var attacker_order := order if attacker == ally_squad else TacticalOrder.Order.NONE
	var defender_order := order if defender == ally_squad else TacticalOrder.Order.NONE
	battle_log = CombatResolver.resolve(attacker, defender, attacker_order, defender_order)
	await _play_log()
	result = CombatResolver.get_result(battle_log).duplicate()
	result["order"] = order
	result["context"] = context
	result["effects"] = BattleConsequences.compute(result, ally_squad, enemy_squad, get_player_side(),
		WorldState.active_flags.merged(EssenceState.decisions))
	_show_result()


func _play_log() -> void:
	for event: Dictionary in battle_log:
		match String(event["type"]):
			"round_start":
				_status.text = "Rodada %d" % int(event["round"])
			"action":
				var card := _cards.get("%s:%d" % [event["target_side"], event["target_index"]]) as UnitCardView
				if card:
					card.show_values(int(event["target_hp"]), int(event["target_morale"]))
				_status.text = _describe_action(event)
			"leader_fallen":
				_status.text = "O líder caiu!"
			_:
				continue
		if step_seconds > 0.0:
			await get_tree().create_timer(step_seconds).timeout


func _describe_action(event: Dictionary) -> String:
	var actor: UnitInstance = _squad_for(String(event["actor_side"])).units[int(event["actor_index"])]
	var target: UnitInstance = _squad_for(String(event["target_side"])).units[int(event["target_index"])]
	var era: EraConfig = WorldState.era_config
	var hp_label: String = era.hp_label if era else "HP"
	var morale_label: String = era.morale_label if era else "Moral"
	if int(event["heal"]) > 0:
		return "%s usa %s em %s (+%d %s)" % [actor.unit_name, event["skill"], target.unit_name, event["heal"], hp_label]
	return "%s usa %s em %s (-%d %s, -%d %s)" % [actor.unit_name, event["skill"], target.unit_name,
		event["damage"], hp_label, event["morale_damage"], morale_label]


func _show_result() -> void:
	var era: EraConfig = WorldState.era_config
	var effects: Dictionary = result["effects"]
	var won: bool = bool(effects["player_won"])
	var title: String = era.get_outcome_label("victory" if won else "defeat") if era else ("Vitória" if won else "Derrota")
	var kind: String = era.get_outcome_label(String(result["victory_type"])) if era else String(result["victory_type"])
	_result_label.text = "%s — %s" % [title, kind]
	_result_panel.show()
	print("BATTLE_RESULT|%s|%s|rounds=%d" % [result["winner"], result["victory_type"], result["rounds"]])
	EventBus.battle_ended.emit(result)


func _on_continue() -> void:
	closed.emit(result)


func _squad_for(side: String) -> SquadData:
	var ally_is_attacker: bool = get_player_side() == "attacker"
	return ally_squad if (side == "attacker") == ally_is_attacker else enemy_squad


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
			card.position = Vector2(rows[unit.get_row()], COLUMN_Y[unit.get_column()])
			_units_root.add_child(card)
			card.setup(unit, color)
			_cards["%s:%d" % [side, i]] = card


func _build_order_buttons(era: EraConfig) -> void:
	for order: int in [TacticalOrder.Order.FOCUS_LEADER, TacticalOrder.Order.FOCUS_WEAK, TacticalOrder.Order.SPARE]:
		var button := Button.new()
		button.text = era.get_order_label(order) if era else str(order)
		button.custom_minimum_size = Vector2(90, 26)
		button.pressed.connect(start_battle.bind(order))
		_orders_box.add_child(button)


## Execução isolada da cena (F6): usa o 1º esquadrão aliado e a 1ª guarnição da era.
func _load_demo_squads() -> void:
	var era: EraConfig = WorldState.era_config
	ally_squad = era.starting_squads[0].clone()
	for node_data: MapNodeData in era.map_nodes:
		if node_data.garrison:
			enemy_squad = node_data.garrison.clone()
			context = {"node_id": node_data.node_id, "player_side": "attacker"}
			return

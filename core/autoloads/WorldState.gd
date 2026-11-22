extends Node
## Estado VISÍVEL do ato atual (Alinhamento, Apoio, Doutrina).
## É reiniciado por EssenceState.archive_act_and_reset_visible() na "Derrota Falsa".

const DEFAULT_ALIGNMENT: int = 50
const DEFAULT_SUPPORT: int = 50
const DEFAULT_RESOURCES: int = 500
const START_ERA_SETTING: String = "game/start_era_config"

# --- Contrato (ARCHITECTURE.md §5) ---
var current_act: int = 1
var alignment: int = DEFAULT_ALIGNMENT       # 0 (Brutal/Mal) .. 100 (Honrado/Bem)
var popular_support: int = DEFAULT_SUPPORT   # 0 .. 100 (Chaos Frame / Mandato do Céu)
var doctrine: int = 0                        # -100 (Pacifista) .. +100 (Revolucionária)
var resources: int = DEFAULT_RESOURCES       # Ouro (I-III), Capital/Dados (IV), Energia/Sinal (V)
var is_paused: bool = true
var captured_nodes: Dictionary = {}          # node_id -> faction_id

# --- Extensões do ato atual ---
var era_config: EraConfig
var day_count: int = 1
var player_squads: Array[SquadData] = []
var active_flags: Dictionary = {}            # Flags locais (eventos já disparados etc.)
var act_echoes: Array[String] = []           # Escolhas marcantes do ato (arquivadas ao fim do ato)
var time_of_day: String = "day"              # "day" | "night" (afeta patrulhas e encontros)
var completed_interludes: Array[String] = [] # Timelines de interlúdio já vividas neste ato
var inventory: Array[ItemData] = []          # Itens do ato atual (drops, recompensas de chefes)
var unlocked_classes: Array[String] = []     # class_id liberados para recrutamento
## Cerco por nó: { node_id: { "mode": "thirst"|"preaching"|"assault"|"poisoned",
##   "sorties": int, "income_bonus": int, "garrison_hp_pct": int } }
var siege: Dictionary = {}
var faction_trust: Dictionary = {}           # fac_id -> int (confiança de facções narrativas; dados da era)


func _ready() -> void:
	var start_path: String = ProjectSettings.get_setting(START_ERA_SETTING, "")
	if not start_path.is_empty():
		load_era(start_path)


## Carrega o EraConfig ativo e aplica o Theme de UI. O motor não muda; só os dados.
func load_era(config_path: String) -> EraConfig:
	var config := load(config_path) as EraConfig
	if config == null:
		push_error("WorldState: EraConfig inválido em '%s'" % config_path)
		return null
	era_config = config
	current_act = config.act_number
	get_tree().root.theme = config.ui_theme
	if not config.window_title.is_empty():
		get_window().title = config.window_title
	EventBus.era_loaded.emit(config)
	_notify()
	return config


## Limpa o estado visível (chamado na "Derrota Falsa").
func reset_visible(next_act: int) -> void:
	current_act = next_act
	alignment = DEFAULT_ALIGNMENT
	popular_support = DEFAULT_SUPPORT
	doctrine = 0
	resources = DEFAULT_RESOURCES
	is_paused = true
	captured_nodes.clear()
	day_count = 1
	player_squads.clear()
	active_flags.clear()
	act_echoes.clear()
	time_of_day = "day"
	completed_interludes.clear()
	inventory.clear()
	unlocked_classes.clear()
	siege.clear()
	faction_trust.clear()
	_notify()


func set_paused(value: bool) -> void:
	if is_paused == value:
		return
	is_paused = value
	EventBus.pause_toggled.emit(value)


func advance_day() -> void:
	day_count += 1
	set_time_of_day("day")
	_notify()


func set_time_of_day(value: String) -> void:
	if time_of_day == value:
		return
	time_of_day = value
	EventBus.time_of_day_changed.emit(value)
	_notify()


func change_alignment(delta: int) -> void:
	alignment = clampi(alignment + delta, 0, 100)
	for squad: SquadData in player_squads:
		squad.change_alignment(delta)
	_notify()


func change_support(delta: int) -> void:
	popular_support = clampi(popular_support + delta, 0, 100)
	_notify()


func change_doctrine(delta: int) -> void:
	doctrine = clampi(doctrine + delta, -100, 100)
	_notify()


func change_resources(delta: int) -> void:
	resources = maxi(0, resources + delta)
	_notify()


func capture_node(node_id: String, faction_id: String) -> void:
	var previous: String = captured_nodes.get(node_id, "")
	captured_nodes[node_id] = faction_id
	if previous != faction_id:
		EventBus.node_captured.emit(node_id, faction_id)
		_notify()


func get_node_faction(node_id: String) -> String:
	return captured_nodes.get(node_id, "neutral")


func count_nodes_of(faction_id: String) -> int:
	return captured_nodes.values().count(faction_id)


func set_flag(flag: String, value: bool = true) -> void:
	active_flags[flag] = value


func has_flag(flag: String) -> bool:
	return bool(active_flags.get(flag, false))


func add_echo(echo_id: String) -> void:
	if echo_id not in act_echoes:
		act_echoes.append(echo_id)


## Efeitos determinísticos (dilemas, combates). Chaves: alignment, popular_support,
## doctrine, resources, flag, echo.
func apply_effects(effects: Dictionary) -> void:
	if effects.has("alignment"):
		change_alignment(int(effects["alignment"]))
	if effects.has("popular_support"):
		change_support(int(effects["popular_support"]))
	if effects.has("doctrine"):
		change_doctrine(int(effects["doctrine"]))
	if effects.has("resources"):
		change_resources(int(effects["resources"]))
	if effects.has("flag"):
		set_flag(String(effects["flag"]))
	if effects.has("echo"):
		add_echo(String(effects["echo"]))
	if effects.has("charisma"):
		for squad: SquadData in player_squads:
			for unit: UnitInstance in squad.units:
				unit.charisma = clampi(unit.charisma + int(effects["charisma"]), 0, 100)
	if effects.has("trust"):  # Formato "fac_id:+N"
		var trust: PackedStringArray = String(effects["trust"]).split(":")
		faction_trust[trust[0]] = int(faction_trust.get(trust[0], 0)) + int(trust[1])
	for key: String in ["siege_mode", "sorties", "income_bonus", "garrison_hp_pct"]:
		if effects.has(key):  # Formato "node_id:valor"
			var parts: PackedStringArray = String(effects[key]).split(":")
			set_siege(parts[0], "mode" if key == "siege_mode" else key, parts[1] if key == "siege_mode" else int(parts[1]))


func set_siege(node_id: String, key: String, value: Variant) -> void:
	var entry: Dictionary = siege.get(node_id, {})
	entry[key] = value
	siege[node_id] = entry
	_notify()


func get_siege(node_id: String, key: String, default: Variant) -> Variant:
	return (siege.get(node_id, {}) as Dictionary).get(key, default)


## % de renda de um nó (100 = normal), ex.: cidade que se rendeu intacta.
func income_pct(node_id: String) -> int:
	return 100 + int(get_siege(node_id, "income_bonus", 0))


func add_item(item: ItemData) -> bool:
	if item == null or (item.unique and has_item(item.item_id)):
		return false
	inventory.append(item)
	_notify()
	return true


func has_item(item_id: String) -> bool:
	return inventory.any(func(item: ItemData) -> bool: return item.item_id == item_id)


func count_item(item_id: String) -> int:
	return inventory.filter(func(item: ItemData) -> bool: return item.item_id == item_id).size()


## Remove 1 unidade do item; retorna false se não houver.
func consume_item(item_id: String) -> bool:
	for i: int in inventory.size():
		if inventory[i].item_id == item_id:
			inventory.remove_at(i)
			_notify()
			return true
	return false


func unlock_class(class_id: String) -> void:
	if class_id not in unlocked_classes:
		unlocked_classes.append(class_id)
		_notify()


## Multiplicador de marcha dos esquadrões do jogador vindo de itens (1.0 = normal).
func item_march_multiplier() -> float:
	var bonus: int = 0
	for item: ItemData in inventory:
		bonus += item.march_speed_bonus_pct
	return 1.0 + float(bonus) / 100.0


func reveals_night_encounters() -> bool:
	return inventory.any(func(item: ItemData) -> bool: return item.reveals_night_encounters)


func _notify() -> void:
	EventBus.world_state_changed.emit()

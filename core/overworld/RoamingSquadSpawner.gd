class_name RoamingSquadSpawner
extends Node
## Gera patrulhas errantes por região, hora do dia e nível do jogador (diff §5).
## Determinístico: a semente vem de (ato, dia, período, região) — mesmo estado, mesmo encontro.

var map: OverworldMap


func setup(p_map: OverworldMap) -> void:
	map = p_map
	EventBus.time_of_day_changed.connect(_on_time_changed)


func _on_time_changed(time_of_day: String) -> void:
	if time_of_day == "day":
		_dismiss_night_squads()
	try_spawn()


func roaming_count() -> int:
	return map.tokens.filter(func(t: SquadToken) -> bool: return t.squad.is_roaming).size()


## Tenta gerar 1 patrulha por tabela; retorna os esquadrões criados.
## O nó é sorteado primeiro (só nós da região da tabela); o encontro precisa servir àquela região.
func try_spawn() -> Array[SquadData]:
	var spawned: Array[SquadData] = []
	var era: EraConfig = WorldState.era_config
	if era == null:
		return spawned
	for resource: Resource in era.encounter_tables:
		var table := resource as EncounterTable
		if table == null or roaming_count() >= era.max_roaming_squads:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([WorldState.current_act, WorldState.day_count, WorldState.time_of_day, table.region_id])
		if rng.randi_range(1, 100) > table.spawn_chance:
			continue
		var node_id: String = _free_spawn_node(table, rng)
		if node_id.is_empty():
			continue
		var region: String = (map.nodes[node_id] as MapNode).data.region_id
		var entry: EncounterEntry = table.pick(rng, WorldState.time_of_day, party_level(), region)
		if entry == null:
			continue
		var squad := entry.squad.clone()
		squad.current_node_id = node_id
		squad.is_roaming = true
		squad.roaming_until_day = entry.time_of_day == "night"
		map.spawn_token(squad)
		spawned.append(squad)
	return spawned


func party_level() -> float:
	var total: float = 0.0
	for squad: SquadData in WorldState.player_squads:
		total += squad.average_level()
	return total / maxf(1.0, float(WorldState.player_squads.size()))


func _free_spawn_node(table: EncounterTable, rng: RandomNumberGenerator) -> String:
	var free: Array[String] = []
	for node_id: String in table.spawn_nodes:
		var occupied: bool = map.tokens.any(func(t: SquadToken) -> bool: return t.squad.current_node_id == node_id)
		var in_region: bool = map.nodes.has(node_id) \
			and (map.nodes[node_id] as MapNode).data.region_id == table.region_id
		if in_region and not occupied:
			free.append(node_id)
	return "" if free.is_empty() else free[rng.randi_range(0, free.size() - 1)]


## Ao amanhecer, encontros noturnos (ex.: cortejos de Jiangshi) se desfazem.
func _dismiss_night_squads() -> void:
	for token: SquadToken in map.tokens.duplicate():
		if token.squad.is_roaming and token.squad.roaming_until_day:
			map.remove_token(token)

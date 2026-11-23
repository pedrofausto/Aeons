class_name SiegeWaterRule
extends Node
## Regra de cerco do Ato II (EraConfig.enable_siege_water_rule). Uma fortaleza fica
## "cercada" quando sua fonte de água (MapNodeData.water_source_node) pertence ao adversário.
## O modo do cerco (WorldState.siege, definido por dilemas) decide o que acontece a cada dia:
##   thirst / poisoned -> sede: -HP (sem matar) e -Moral nos defensores
##   preaching         -> sem sede; -Moral diária, surtidas pendentes e rendição intacta
##   assault           -> a água corre; nada acontece até o assalto

const THIRST_HP_PCT: int = 8
const THIRST_MORALE: int = 15
const PREACHING_MORALE: int = 12

var map: OverworldMap


func setup(p_map: OverworldMap) -> void:
	map = p_map
	EventBus.tick_advanced.connect(func(_day: int) -> void: apply())
	EventBus.interlude_choice_applied.connect(apply_immediate)


## Aplica o dia de cerco; retorna os node_id cercados.
func apply() -> Array[String]:
	var besieged: Array[String] = []
	var era: EraConfig = WorldState.era_config
	if era == null or not era.enable_siege_water_rule:
		return besieged
	for node_id: String in map.nodes:
		if not is_cut_off(node_id):
			continue
		besieged.append(node_id)
		var name: String = (map.nodes[node_id] as MapNode).data.display_name
		match String(WorldState.get_siege(node_id, "mode", "thirst")):
			"preaching":
				_preach(node_id)
				map.show_banner(era.siege_preaching_message % name, 3.0)
			"assault":
				pass
			_:
				for squad: SquadData in defenders(node_id):
					squad.suffer_thirst(THIRST_HP_PCT, THIRST_MORALE)
				map.show_banner(era.siege_thirst_message % name, 3.0)
	return besieged


## A fortaleza está ocupada e a água pertence a outra facção (que não neutra).
func is_cut_off(node_id: String) -> bool:
	var data: MapNodeData = (map.nodes[node_id] as MapNode).data
	if data.water_source_node.is_empty() or not map.nodes.has(data.water_source_node):
		return false
	var holder: String = WorldState.get_node_faction(node_id)
	var water: String = WorldState.get_node_faction(data.water_source_node)
	return holder != "neutral" and water != "neutral" and water != holder


## Esquadrões parados que defendem o nó (mesma facção do dono).
func defenders(node_id: String) -> Array[SquadData]:
	var found: Array[SquadData] = []
	var holder: String = WorldState.get_node_faction(node_id)
	for token: SquadToken in map.tokens:
		if token.squad.faction == holder and token.squad.current_node_id == node_id and not token.is_moving():
			found.append(token.squad)
	return found


## Efeitos imediatos de um dilema: dano à guarnição e reforços.
func apply_immediate(effects: Dictionary) -> void:
	if effects.has("garrison_hp_pct"):
		var parts: PackedStringArray = String(effects["garrison_hp_pct"]).split(":")
		for squad: SquadData in defenders(parts[0]):
			for unit: UnitInstance in squad.get_living_units():
				unit.ensure_vitals()  # hp -1 = cheio: converte antes de aplicar a porcentagem
				unit.hp = maxi(1, unit.hp * int(parts[1]) / 100)
	if effects.has("reinforce") and map.nodes.has(String(effects["reinforce"])):
		var node_id: String = effects["reinforce"]
		var extra: SquadData = (map.nodes[node_id] as MapNode).data.siege_reinforcements
		for squad: SquadData in defenders(node_id):
			for unit: UnitInstance in (extra.clone().units if extra else []):
				var slot: int = squad.first_free_slot()
				if slot >= 0:
					unit.slot = slot
					squad.units.append(unit)
			break


## Cerco pacífico: a fé dos mercenários cede; surtidas saem uma a uma; por fim, rendição.
func _preach(node_id: String) -> void:
	var garrison: Array[SquadData] = defenders(node_id)
	for squad: SquadData in garrison:
		for unit: UnitInstance in squad.get_living_units():
			SkillMath.drain_morale(unit, PREACHING_MORALE)
	var pending: int = int(WorldState.get_siege(node_id, "sorties", 0))
	var active: bool = map.tokens.any(func(k: SquadToken) -> bool: return k.squad.encounter_tag == "siege_sortie")
	var data: MapNodeData = (map.nodes[node_id] as MapNode).data
	if pending > 0 and not active and data.sortie_squad:
		var sortie := data.sortie_squad.clone()
		sortie.current_node_id = node_id
		sortie.patrol_route = [node_id, data.water_source_node]
		sortie.encounter_tag = "siege_sortie"
		map.spawn_token(sortie)
		WorldState.set_siege(node_id, "sorties", pending - 1)
		return
	if pending == 0 and not active and garrison.all(func(s: SquadData) -> bool: return s.is_routed() or s.is_annihilated()):
		for token: SquadToken in map.tokens.duplicate():
			if token.squad.squad_id in garrison.map(func(s: SquadData) -> String: return s.squad_id):
				map.remove_token(token)
		map.capture(node_id)
		map.show_banner(WorldState.era_config.siege_surrender_message % data.display_name, 4.0)
		map.on_encounter_resolved()

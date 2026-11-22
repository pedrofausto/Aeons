class_name SiegeWaterRule
extends Node
## Regra de cerco do Ato II (EraConfig.enable_siege_water_rule): a cada dia, quem guarda
## uma fortaleza cuja fonte de água (MapNodeData.water_source_node) está nas mãos do
## adversário sofre sede — perde HP (sem morrer) e Moral. Cortar a água decide o cerco.

const THIRST_HP_PCT: int = 8
const THIRST_MORALE: int = 15

var map: OverworldMap


func setup(p_map: OverworldMap) -> void:
	map = p_map
	EventBus.tick_advanced.connect(func(_day: int) -> void: apply())


## Aplica a sede do dia; retorna os node_id cercados sem água.
func apply() -> Array[String]:
	var parched: Array[String] = []
	var era: EraConfig = WorldState.era_config
	if era == null or not era.enable_siege_water_rule:
		return parched
	for node_id: String in map.nodes:
		if not is_cut_off(node_id):
			continue
		parched.append(node_id)
		var holder: String = WorldState.get_node_faction(node_id)
		for token: SquadToken in map.tokens:
			if token.squad.faction == holder and token.squad.current_node_id == node_id and not token.is_moving():
				token.squad.suffer_thirst(THIRST_HP_PCT, THIRST_MORALE)
		map.show_banner(era.siege_thirst_message % (map.nodes[node_id] as MapNode).data.display_name, 3.0)
	return parched


## A fortaleza está ocupada e a água pertence a outra facção (que não neutra).
func is_cut_off(node_id: String) -> bool:
	var data: MapNodeData = (map.nodes[node_id] as MapNode).data
	if data.water_source_node.is_empty() or not map.nodes.has(data.water_source_node):
		return false
	var holder: String = WorldState.get_node_faction(node_id)
	var water: String = WorldState.get_node_faction(data.water_source_node)
	return holder != "neutral" and water != "neutral" and water != holder

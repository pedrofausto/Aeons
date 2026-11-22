class_name PatrolAI
extends RefCounted
## IA determinística de patrulha: percorre `SquadData.patrol_route` em laço.

const SPEED_FACTOR: float = 0.55   # Patrulhas marcham mais devagar que o jogador


## Próximo trecho de marcha a partir do nó atual (vazio se não houver rota).
static func next_leg(squad: SquadData, graph: Dictionary) -> Array[String]:
	var route: Array[String] = squad.patrol_route
	if route.size() < 2:
		return []
	var index: int = route.find(squad.current_node_id)
	var target: String = route[(index + 1) % route.size()] if index >= 0 else route[0]
	return MapGraph.find_path(graph, squad.current_node_id, target)

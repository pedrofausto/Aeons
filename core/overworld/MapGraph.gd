class_name MapGraph
extends RefCounted
## Utilitário puro de grafo do mapa (sem nós visuais).


## Menor caminho por BFS determinística. `graph` = { node_id: Array[String] vizinhos }.
## Retorna os nós a visitar (sem incluir a origem); vazio se não houver rota.
static func find_path(graph: Dictionary, from_id: String, to_id: String) -> Array[String]:
	var route: Array[String] = []
	if from_id == to_id or not graph.has(from_id) or not graph.has(to_id):
		return route
	var previous: Dictionary = {from_id: ""}
	var queue: Array[String] = [from_id]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		if current == to_id:
			break
		for next_id: String in graph[current]:
			if not previous.has(next_id):
				previous[next_id] = current
				queue.append(next_id)
	if not previous.has(to_id):
		return route
	var cursor: String = to_id
	while cursor != from_id:
		route.push_front(cursor)
		cursor = previous[cursor]
	return route


## Desenha as estradas do grafo; trechos que tocam um nó SEA viram rota marítima tracejada.
static func draw_roads(canvas: CanvasItem, nodes: Dictionary, era: EraConfig) -> void:
	for node_id: String in nodes:
		var from: MapNode = nodes[node_id]
		for next_id: String in from.data.neighbors:
			if not nodes.has(next_id) or node_id >= next_id:
				continue
			var to: MapNode = nodes[next_id]
			if MapNodeData.NodeType.SEA in [from.data.node_type, to.data.node_type]:
				canvas.draw_dashed_line(from.position, to.position, era.color_sea_lane, 2.0, 6.0)
			else:
				canvas.draw_line(from.position, to.position, era.color_road, 3.0)

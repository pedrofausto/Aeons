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

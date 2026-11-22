class_name EncounterTable
extends Resource
## Tabela de encontros de uma província/região (comum, noturno, escolta moral, chefe secreto).

@export var region_id: String = ""
@export var spawn_nodes: Array[String] = []      # Onde patrulhas errantes podem surgir
@export_range(0, 100) var spawn_chance: int = 50 # % por meio-dia, se houver vaga
@export var entries: Array[EncounterEntry] = []


## Escolha ponderada e determinística (o RNG chega semeado pelo estado do mundo).
func pick(rng: RandomNumberGenerator, current_time: String, party_level: float) -> EncounterEntry:
	var available: Array[EncounterEntry] = []
	var total: int = 0
	for entry: EncounterEntry in entries:
		if entry.is_available(current_time, party_level):
			available.append(entry)
			total += entry.weight
	if total == 0:
		return null
	var roll: int = rng.randi_range(1, total)
	for entry: EncounterEntry in available:
		roll -= entry.weight
		if roll <= 0:
			return entry
	return available.back()

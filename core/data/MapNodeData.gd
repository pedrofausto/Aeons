class_name MapNodeData
extends Resource
## ID, tipo, facção inicial, ouro/tick, vizinhos e gatilho de evento de um nó do mapa.

enum NodeType { CITY, FORTRESS, RESOURCE, SERVER, PASS }

@export var node_id: String = ""
@export var display_name: String = ""
@export var node_type: NodeType = NodeType.CITY
@export var faction: String = "neutral"      # Facção inicial: "player" | "enemy" | "neutral"
@export var region_id: String = ""           # Província/região (filtra encontros do spawner)
@export_enum("plains", "mountain", "river", "forest", "urban") var terrain: String = "plains"
@export var required_for_victory: bool = true  # false = objetivo opcional (não bloqueia a vitória)
@export var water_source_node: String = ""   # Regra de cerco: quem não controla a água sofre sede
@export var sortie_squad: SquadData          # Surtidas da guarnição durante um cerco (dilemas)
@export var siege_reinforcements: SquadData  # Reforços que entram na guarnição (dilemas)
@export var gold_per_tick: int = 10          # Renda por dia (tick) enquanto aliado
@export var map_position: Vector2 = Vector2.ZERO
@export var neighbors: Array[String] = []
@export var garrison: SquadData              # Esquadrão estacionado no início (opcional)
@export_file("*.dtl") var liberation_timeline: String = ""  # Interlúdio na 1ª vez sob controle aliado
@export var liberation_title: String = ""    # Título exibido na sala do interlúdio
@export_enum("below", "above") var label_side: String = "below"  # Evita sobrepor rótulos vizinhos

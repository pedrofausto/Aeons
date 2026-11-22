class_name EraConfig
extends Resource
## Tema UI, paleta, vocabulário, regras extras e lista de nós/unidades de uma era.

@export var act_number: int = 1
@export var era_title: String = ""
@export var window_title: String = ""
@export var ui_theme: Theme
@export var palette_shader: ShaderMaterial                      # Pós-processo de paleta (opcional)
@export_enum("PHYSICAL_WAR", "RESOURCE_NETWORK", "VIRTUAL_COGNITIVE")
var reality_layer: String = "PHYSICAL_WAR"
@export_enum("camp", "clandestine_physical", "ephemeral_metaphysical")
var interlude_style: String = "camp"

@export_group("Vocabulário da UI")
@export var resource_label: String = "Ouro"          # "Ouro" | "Capital" | "Dados" | "Sinal"
@export var hp_label: String = "HP"                  # "HP" | "Sigilo" | "Sinal"
@export var morale_label: String = "Moral"           # "Moral" | "Credibilidade" | "Lucidez"
@export var alignment_label: String = "Alinhamento"
@export var support_label: String = "Apoio Popular"
@export var doctrine_label: String = "Doutrina"
@export var day_label: String = "Dia"
@export var time_of_day_labels: Dictionary = {"day": "☀", "night": "☾"}
## Rótulos das ordens táticas, na ordem de TacticalOrder.Order (NONE, FOCUS_LEADER, FOCUS_WEAK, SPARE).
@export var order_labels: PackedStringArray = ["Sem Ordem", "Focar Líder", "Focar Fraco", "Poupar/Render"]
## Rótulos de desfecho do combate (chaves: victory, defeat, annihilation, morale_break, timeout).
@export var outcome_labels: Dictionary = {
	"victory": "Vitória", "defeat": "Derrota",
	"annihilation": "Aniquilação", "morale_break": "Rendição por Moral", "timeout": "Retirada",
}

@export_group("Paleta")
@export var color_player: Color = Color(0.85, 0.7, 0.35)
@export var color_enemy: Color = Color(0.75, 0.2, 0.2)
@export var color_neutral: Color = Color(0.55, 0.55, 0.55)
@export var color_background: Color = Color(0.08, 0.09, 0.08)
@export var color_road: Color = Color(0.45, 0.4, 0.3)

@export_group("Interlúdio (Dialogic, resolução lógica 640x360)")
@export var dialogue_font_size: int = 9
@export var dialogue_box_size: Vector2 = Vector2(520, 70)
@export var dialogue_box_margin_bottom: int = 8

@export_group("Regras Extras")
@export var enable_siege_water_rule: bool = false    # Ato II (Carcassonne)
@export var enable_offmap_artillery: bool = false    # Ato III (Grandes Guerras)
@export var enable_network_hack: bool = false        # Atos IV-V
@export var dissolve_interlude_shader: Shader        # Ato V (Encontros efêmeros)

@export_group("Conteúdo")
@export var map_nodes: Array[MapNodeData] = []
@export var unit_classes: Array[UnitClassData] = []
@export var starting_squads: Array[SquadData] = []
@export var enemy_patrols: Array[SquadData] = []       # Esquadrões com patrol_route
@export var encounter_tables: Array[Resource] = []     # EncounterTable por província/região
@export var max_roaming_squads: int = 2
@export var victory_text: String = ""
@export var recruit_message: String = "%s se junta à %s."        # (recrutado, esquadrão)
@export var item_message: String = "Obtido: %s"
@export_file("*.tres") var next_era_config: String = ""


func get_order_label(order: int) -> String:
	return order_labels[order] if order >= 0 and order < order_labels.size() else str(order)


func get_outcome_label(key: String) -> String:
	return String(outcome_labels.get(key, key))


func color_for_faction(faction_id: String) -> Color:
	match faction_id:
		"player":
			return color_player
		"enemy":
			return color_enemy
	return color_neutral

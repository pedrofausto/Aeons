class_name UnitClassData
extends Resource

enum Archetype { VANGUARD, SHOCK, RANGED_STEALTH, ARCANE_TECH, HEALER_MORAL, BARD_INFLUENCE, MYTHIC }

@export var class_id: String = ""
@export var display_name: String = ""
@export var era_id: int = 1
@export var archetype: Archetype = Archetype.VANGUARD
@export var grid_slots: int = 1              # 1 = padrão | 2 = unidade colossal (ex.: Tarasque)
@export_range(1, 3) var tier: int = 1        # 1 = Base | 2 = Elite/Sombria | 3 = Mítica/Secreta
@export var liberation_reputation_bonus: int = 0  # Apoio Popular ao libertar nós (negativo: saqueadores)
## Subtipo livre (o enum de arquétipos é fixo): undead, celestial, trickster, evil_shaman,
## morale_immune (moral nunca cai), status_immune (CONFUSE/POISON), flying.
@export var traits: PackedStringArray = []
@export var placeholder_color: Color = Color(0, 0, 0, 0)  # Alfa 0 = cor do arquétipo

@export_group("Resistências")
## % de dano recebido por elemento (100 = normal). Ex.: {"PHYSICAL": 20, "SPIRITUAL": 150}
@export var damage_taken_pct: Dictionary = {}

@export_group("Movimento no Mapa")
## ground = Infantaria | cavalry | mountain | swamp | ethereal | flying (ver SquadData.TERRAIN_FACTORS)
@export_enum("ground", "flying", "cavalry", "mountain", "swamp", "ethereal") var movement: String = "ground"
@export var march_speed_pct: int = 100
@export var night_march_bonus_pct: int = 0

@export_group("Stats Base")
@export var max_hp: int = 100
@export var max_morale: int = 100
@export var attack: int = 15
@export var defense: int = 10
@export var intellect: int = 10
@export var agility: int = 10

@export_group("Ações por Fileira (Grade 3x2)")
@export var front_action: ActionSkillData
@export var back_action: ActionSkillData

@export_group("Promoção Estilo Ogre Battle")
## Contém apenas UnitClassData. Tipado como Resource porque um Array[UnitClassData]
## dentro do próprio UnitClassData cria um ciclo de script que vaza na saída (Godot 4.7).
@export var promotes_to: Array[Resource] = []   # Promoções extras/neutras
@export var promotion_good: Resource             # UnitClassData de Alto Alinhamento
@export var promotion_evil: Resource             # UnitClassData de Baixo Alinhamento
@export_enum("any", "pacifist", "revolutionary") var preferred_doctrine: String = "any"


## Todas as classes de destino possíveis (boa, sombria e extras), sem nulos.
func get_promotion_targets() -> Array[UnitClassData]:
	var targets: Array[UnitClassData] = []
	for entry: Resource in [promotion_good, promotion_evil] + promotes_to:
		var target := entry as UnitClassData
		if target != null and target not in targets:
			targets.append(target)
	return targets


func has_trait(trait_name: String) -> bool:
	return trait_name in traits


func damage_multiplier_pct(element_name: String) -> int:
	return int(damage_taken_pct.get(element_name, 100))


## Doutrina (-100..+100) compatível com a preferência da classe.
func matches_doctrine(doctrine: int) -> bool:
	match preferred_doctrine:
		"pacifist":
			return doctrine <= 0
		"revolutionary":
			return doctrine >= 0
	return true
@export var min_level: int = 1
@export var min_alignment: int = 0           # 0..100
@export var max_alignment: int = 100
@export var min_charisma: int = 0
@export var min_doctrine: int = -100         # Doutrina do ato (WorldState.doctrine) exigida
@export var max_doctrine: int = 100
@export var forbidden_flag: String = ""       # Promoção recusada enquanto esta flag estiver ativa
## Item consumido (1 unidade) ao promover PARA esta classe. Vazio = sem item.
@export var required_item_id: StringName = &""

@export_group("Visuais (opcionais)")
@export var sprite_texture: Texture2D
@export var portrait_texture: Texture2D

class_name UnitClassData
extends Resource

enum Archetype { VANGUARD, SHOCK, RANGED_STEALTH, ARCANE_TECH, HEALER_MORAL, BARD_INFLUENCE, MYTHIC }

@export var class_id: String = ""
@export var display_name: String = ""
@export var era_id: int = 1
@export var archetype: Archetype = Archetype.VANGUARD
@export var grid_slots: int = 1              # 1 = padrão | 2 = unidade colossal (ex.: Tarasque)

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
@export var promotes_to: Array[Resource] = []
@export var min_level: int = 1
@export var min_alignment: int = 0           # 0..100
@export var max_alignment: int = 100
@export var min_charisma: int = 0

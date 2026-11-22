class_name ActionSkillData
extends Resource
## Ação executada por uma unidade conforme a fileira em que está na grade 3x2.
## Campos opcionais (elemento, golpes, dreno, status, buffs) têm padrões neutros.

enum Effect { PHYSICAL, MAGIC, MORALE_ONLY, HEAL }
enum Targeting { FRONT_FIRST, BACK_FIRST, ALL_ENEMIES, LEADER, LOWEST_HP_ALLY, ALL_ALLIES }

@export var skill_id: String = ""
@export var display_name: String = ""
@export var effect: Effect = Effect.PHYSICAL
@export var targeting: Targeting = Targeting.FRONT_FIRST
@export var power: int = 100                 # % do atributo ofensivo (attack ou intellect)
@export var morale_power: int = 0            # Dano de moral adicional por golpe (ou moral curada)

@export_group("Modificadores (opcionais)")
## Vazio = derivado do efeito (PHYSICAL -> "PHYSICAL", MAGIC -> "ARCANE").
## Outros: SHADOW, SPIRITUAL, PURIFY, FIRE.
@export var element: String = ""
@export_range(1, 4) var hits: int = 1         # Golpes por ação ("2x Dreno Vital")
@export_range(0, 100) var lifesteal_pct: int = 0
@export_range(0, 100) var armor_pierce_pct: int = 0
@export var inflicts_status: String = ""      # Ex.: "CONFUSE" (perde a próxima ação)
@export var ally_buff_trait: String = ""      # Aliados com este trait recebem buff de ataque
@export var ally_buff_attack_pct: int = 0
@export var healthy_allies_bonus_power: int = 0  # Dano em área se todos os aliados > 80% HP
@export var bonus_element: String = "SPIRITUAL"


func is_offensive() -> bool:
	return effect != Effect.HEAL


func get_element() -> String:
	if not element.is_empty():
		return element
	return "ARCANE" if effect == Effect.MAGIC else "PHYSICAL"

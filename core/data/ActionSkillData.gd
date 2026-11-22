class_name ActionSkillData
extends Resource
## Ação executada por uma unidade conforme a fileira em que está na grade 3x2.

enum Effect { PHYSICAL, MAGIC, MORALE_ONLY, HEAL }
enum Targeting { FRONT_FIRST, BACK_FIRST, ALL_ENEMIES, LEADER, LOWEST_HP_ALLY }

@export var skill_id: String = ""
@export var display_name: String = ""
@export var effect: Effect = Effect.PHYSICAL
@export var targeting: Targeting = Targeting.FRONT_FIRST
@export var power: int = 100                 # % do atributo ofensivo (attack ou intellect)
@export var morale_power: int = 0            # Dano de moral adicional por golpe


func is_offensive() -> bool:
	return effect != Effect.HEAL

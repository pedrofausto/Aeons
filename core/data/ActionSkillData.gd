class_name ActionSkillData
extends Resource
## Ação executada por uma unidade conforme a fileira em que está na grade 3x2.
## Campos opcionais (elemento, golpes, dreno, status, buffs) têm padrões neutros.

enum Effect { PHYSICAL, MAGIC, MORALE_ONLY, HEAL, BUFF }  # BUFF: só efeitos de apoio
enum Targeting { FRONT_FIRST, BACK_FIRST, ALL_ENEMIES, LEADER, LOWEST_HP_ALLY, ALL_ALLIES, WEAKEST }

@export var skill_id: String = ""
@export var display_name: String = ""
@export var effect: Effect = Effect.PHYSICAL
@export var targeting: Targeting = Targeting.FRONT_FIRST
@export var power: int = 100                 # % do atributo ofensivo (attack ou intellect)
@export var morale_power: int = 0            # Dano de moral adicional por golpe (ou moral curada)

@export_group("Modificadores (opcionais)")
## Vazio = derivado do efeito (PHYSICAL -> "PHYSICAL", MAGIC -> "ARCANE").
## Outros: SHADOW, SPIRITUAL, PURIFY, FIRE, PIERCE, SIEGE, LIGHT.
@export var element: String = ""
@export_range(1, 4) var hits: int = 1         # Golpes por ação ("2x Dreno Vital")
@export_range(0, 100) var lifesteal_pct: int = 0
@export_range(0, 100) var armor_pierce_pct: int = 0
@export var inflicts_status: String = ""      # Ex.: "CONFUSE" (perde a próxima ação)
@export var ally_buff_trait: String = ""      # Aliados com este trait recebem buff de ataque ("*" = todos)
@export var ally_buff_attack_pct: int = 0
@export var healthy_allies_bonus_power: int = 0  # Dano em área se todos os aliados > 80% HP
@export var bonus_element: String = "SPIRITUAL"
@export_range(0, 90) var ally_guard_pct: int = 0          # Reduz o dano recebido pelo esquadrão (batalha)
@export_range(0, 90) var target_attack_debuff_pct: int = 0  # Reduz o ataque do alvo (batalha)
@export var enemy_morale_drain: int = 0       # Curas: drena Moral de todos os inimigos (rendição)
@export var grants_extra_action: bool = false # Bardo: o aliado mais forte age de novo na hora
@export var resources_on_hit: int = 0         # Moeda do ato ganha por acerto (saque); 0 = nenhum
@export var bonus_terrain: String = ""        # Terreno canônico que dá bônus de poder; "" = desativado
@export var bonus_terrain_power_pct: int = 0  # % somado ao power quando a batalha ocorre nesse terreno


func is_offensive() -> bool:
	return effect != Effect.HEAL and effect != Effect.BUFF


func get_element() -> String:
	if not element.is_empty():
		return element
	return "ARCANE" if effect == Effect.MAGIC else "PHYSICAL"

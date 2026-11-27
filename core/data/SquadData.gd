class_name SquadData
extends Resource
## Grade 3x2 (slots 0..2 frente, 3..5 trás), líder e fadiga.

const SLOT_COUNT: int = 6
const FATIGUE_PER_BATTLE: int = 20
const MAX_FATIGUE: int = 100
## Multiplicador de marcha por perfil de movimento e terreno (1.0 se ausente).
const TERRAIN_FACTORS: Dictionary = {
	"ground": {"mountain": 0.7, "swamp": 0.6},
	"cavalry": {"plains": 1.3, "urban": 1.1, "forest": 0.8, "mountain": 0.5, "swamp": 0.5},
	"mountain": {"swamp": 0.6, "forest": 1.1},
	"swamp": {"mountain": 0.7},
	"flying": {}, "ethereal": {},
}

@export var squad_id: String = ""
@export var display_name: String = ""
@export var faction: String = "player"       # "player" | "enemy" | "neutral"
@export var units: Array[UnitInstance] = []
@export var current_node_id: String = ""
@export_range(0, 100) var fatigue: int = 0   # Reduz ataque em até 30%
@export var patrol_route: Array[String] = []  # Nós percorridos em laço por patrulhas inimigas
## Tag de encontro: bandit_loot | moral_escort | low_level_trap | natural_wildlife | mythic_boss
@export var encounter_tag: String = ""

@export_group("Regras pós-batalha (opcionais)")
@export var supernatural: bool = false            # Sem penalidade de alinhamento por nível
@export var victory_effects: Dictionary = {}      # Somados ao vencer (ex.: {"popular_support": 5})
@export var rare_drop: ItemData
@export_range(0, 100) var rare_drop_chance: int = 0
## Por tipo de vitória: {"morale_break": {"flag": "...", "unlock_class": "..."}, "annihilation": {"item": "res://..."}}
@export var outcome_rewards: Dictionary = {}
## Rota de honra: {"min_alignment": 70, "flag": "...", "counts_as": "morale_break"}
@export var honor_rule: Dictionary = {}

var is_roaming: bool = false          # Gerado pelo RoamingSquadSpawner (não bloqueia a vitória)
var roaming_until_day: bool = false   # Encontro noturno: some ao amanhecer


## Cópia profunda independente (o .tres original nunca é mutado em runtime).
func clone() -> SquadData:
	var copy := SquadData.new()
	copy.squad_id = squad_id
	copy.display_name = display_name
	copy.faction = faction
	copy.current_node_id = current_node_id
	copy.fatigue = fatigue
	copy.patrol_route = patrol_route.duplicate()
	copy.encounter_tag = encounter_tag
	copy.supernatural = supernatural
	copy.victory_effects = victory_effects
	copy.rare_drop = rare_drop
	copy.rare_drop_chance = rare_drop_chance
	copy.outcome_rewards = outcome_rewards
	copy.honor_rule = honor_rule
	copy.is_roaming = is_roaming
	copy.roaming_until_day = roaming_until_day
	for unit: UnitInstance in units:
		var unit_copy := unit.duplicate() as UnitInstance
		unit_copy.ensure_vitals()
		copy.units.append(unit_copy)
	return copy


func is_patrol() -> bool:
	return not patrol_route.is_empty()


## Promove cada unidade para a 1ª classe disponível (estilo Ogre Battle), pulando as
## bloqueadas por falta de item. Retorna "Nome → Classe" de cada promoção feita.
func promote_eligible() -> Array[String]:
	var done: Array[String] = []
	for unit: UnitInstance in units:
		for option: Dictionary in PromotionRules.options_for(unit):
			var target: UnitClassData = option["target"]
			if option["available"] and PromotionRules.promote(unit, target):
				done.append("%s → %s" % [unit.unit_name, target.display_name])
				break
	return done


## Há promoção cumprida em atributos (mesmo que bloqueada por item: a UI mostra o requisito).
func has_eligible_promotion() -> bool:
	for unit: UnitInstance in units:
		if not PromotionRules.options_for(unit).is_empty():
			return true
	return false


## Marcha do esquadrão = a da unidade viva mais lenta (com bônus noturno da classe).
func march_factor(time_of_day: String) -> float:
	var slowest: int = 100
	var first: bool = true
	for unit: UnitInstance in get_living_units():
		var pct: int = unit.class_data.march_speed_pct
		if time_of_day == "night":
			pct += unit.class_data.night_march_bonus_pct
		slowest = pct if first else mini(slowest, pct)
		first = false
	return float(slowest) / 100.0


## A unidade mais lenta no terreno dita o passo do esquadrão.
func terrain_factor(terrain: String) -> float:
	var factor: float = 1.0
	var first: bool = true
	for unit: UnitInstance in get_living_units():
		var table: Dictionary = TERRAIN_FACTORS.get(unit.class_data.movement, {})
		var value: float = float(table.get(terrain, 1.0))
		factor = value if first else minf(factor, value)
		first = false
	return factor


## Soma do bônus de reputação das classes vivas ao libertar um nó.
func liberation_bonus() -> int:
	var total: int = 0
	for unit: UnitInstance in get_living_units():
		total += unit.class_data.liberation_reputation_bonus
	return total


## Sede de cerco: perde % do HP máximo (sem morrer) e Moral (exceto imunes a moral).
func suffer_thirst(hp_pct: int, morale_loss: int) -> void:
	for unit: UnitInstance in get_living_units():
		unit.hp = maxi(1, unit.hp - maxi(1, unit.get_max_hp() * hp_pct / 100))
		if not unit.class_data.has_trait("morale_immune"):
			unit.morale = maxi(0, unit.morale - morale_loss)


## Primeiro slot livre da grade 3x2 (frente antes de trás); -1 se cheia.
func first_free_slot() -> int:
	for slot: int in SLOT_COUNT:
		if get_unit_at(slot) == null:
			return slot
	return -1


## Unidades colossais (grid_slots = 2) ocupam a coluna inteira: slot da frente + o de trás.
func get_unit_at(slot: int) -> UnitInstance:
	for unit: UnitInstance in units:
		if unit.slot == slot or (unit.class_data.grid_slots >= 2 and unit.slot + 3 == slot):
			return unit
	return null


func get_leader() -> UnitInstance:
	for unit: UnitInstance in units:
		if unit.is_leader:
			return unit
	return units[0] if not units.is_empty() else null


func get_living_units() -> Array[UnitInstance]:
	var living: Array[UnitInstance] = []
	for unit: UnitInstance in units:
		if unit.is_alive():
			living.append(unit)
	return living


func is_annihilated() -> bool:
	return get_living_units().is_empty()


## Todas as unidades vivas estão com moral zerada (rendição).
func is_routed() -> bool:
	var living := get_living_units()
	if living.is_empty():
		return false
	for unit: UnitInstance in living:
		if not unit.is_broken():
			return false
	return true


func average_level() -> float:
	if units.is_empty():
		return 0.0
	var total: int = 0
	for unit: UnitInstance in units:
		total += unit.level
	return float(total) / float(units.size())


func average_alignment() -> float:
	if units.is_empty():
		return 50.0
	var total: int = 0
	for unit: UnitInstance in units:
		total += unit.alignment
	return float(total) / float(units.size())


func change_alignment(delta: int) -> void:
	for unit: UnitInstance in units:
		unit.change_alignment(delta)


## Percentual de ataque preservado após a fadiga (100 = descansado).
func fatigue_attack_pct() -> int:
	return 100 - fatigue * 30 / MAX_FATIGUE


func add_fatigue(amount: int) -> void:
	fatigue = clampi(fatigue + amount, 0, MAX_FATIGUE)


## Soma de HP e Moral restantes como fração (0..1) — desempate por tempo.
func vitality_ratio() -> float:
	var current: int = 0
	var maximum: int = 0
	for unit: UnitInstance in units:
		current += maxi(unit.hp, 0) + (maxi(unit.morale, 0) if unit.is_alive() else 0)
		maximum += unit.get_max_hp() + unit.get_max_morale()
	return 0.0 if maximum == 0 else float(current) / float(maximum)


func restore_morale() -> void:
	for unit: UnitInstance in units:
		if unit.is_alive():
			unit.morale = unit.get_max_morale()


## Descanso em nó aliado: cura percentual, reduz fadiga; caídos voltam com HP mínimo.
func rest(percent: int) -> void:
	add_fatigue(-percent)
	for unit: UnitInstance in units:
		var amount: int = maxi(1, unit.get_max_hp() * percent / 100)
		unit.hp = mini(maxi(unit.hp, 0) + amount, unit.get_max_hp())


## Custo diário de manutenção do esquadrão (soma tier * 3 por unidade viva).
func daily_upkeep() -> int:
	var cost: int = 0
	for unit: UnitInstance in get_living_units():
		cost += unit.class_data.tier * 3
	return cost


## Verdadeiro se todo o esquadrão vivo voa (Flying Layer Override no mapa).
func is_airborne() -> bool:
	var living := get_living_units()
	if living.is_empty():
		return false
	for unit: UnitInstance in living:
		if not (unit.class_data.movement in ["flying", "ethereal"] or unit.class_data.has_trait("flying")):
			return false
	return true

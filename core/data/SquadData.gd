class_name SquadData
extends Resource
## Grade 3x2 (slots 0..2 frente, 3..5 trás), líder e fadiga.

const SLOT_COUNT: int = 6
const FATIGUE_PER_BATTLE: int = 20
const MAX_FATIGUE: int = 100

@export var squad_id: String = ""
@export var display_name: String = ""
@export var faction: String = "player"       # "player" | "enemy" | "neutral"
@export var units: Array[UnitInstance] = []
@export var current_node_id: String = ""
@export_range(0, 100) var fatigue: int = 0   # Reduz ataque em até 30%


## Cópia profunda independente (o .tres original nunca é mutado em runtime).
func clone() -> SquadData:
	var copy := SquadData.new()
	copy.squad_id = squad_id
	copy.display_name = display_name
	copy.faction = faction
	copy.current_node_id = current_node_id
	copy.fatigue = fatigue
	for unit: UnitInstance in units:
		var unit_copy := unit.duplicate() as UnitInstance
		unit_copy.ensure_vitals()
		copy.units.append(unit_copy)
	return copy


func get_unit_at(slot: int) -> UnitInstance:
	for unit: UnitInstance in units:
		if unit.slot == slot:
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

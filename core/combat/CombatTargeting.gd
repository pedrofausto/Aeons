class_name CombatTargeting
extends RefCounted
## Escolha determinística de alvos na grade 3x2 (funções puras).


static func pick_targets(skill: ActionSkillData, foes: SquadData, own_order: TacticalOrder.Order) -> Array[int]:
	var candidates: Array[int] = standing_indexes(foes)
	if candidates.is_empty():
		return []
	if skill.targeting == ActionSkillData.Targeting.ALL_ENEMIES:
		return candidates
	if skill.targeting == ActionSkillData.Targeting.LEADER or TacticalOrder.targets_leader(own_order):
		var leader_index: int = foes.units.find(foes.get_leader())
		if leader_index in candidates:
			return [leader_index]
	if TacticalOrder.targets_weakest(own_order):
		return [lowest_hp(foes, candidates)]
	var preferred_row: int = 1 if skill.targeting == ActionSkillData.Targeting.BACK_FIRST else 0
	var in_row: Array[int] = []
	for i: int in candidates:
		if foes.units[i].get_row() == preferred_row:
			in_row.append(i)
	return [lowest_hp(foes, in_row if not in_row.is_empty() else candidates)]


## Menor HP absoluto; empate decidido pelo menor slot.
static func lowest_hp(squad: SquadData, pool: Array[int]) -> int:
	var best: int = pool[0]
	for i: int in pool:
		var unit: UnitInstance = squad.units[i]
		var current: UnitInstance = squad.units[best]
		if unit.hp < current.hp or (unit.hp == current.hp and unit.slot < current.slot):
			best = i
	return best


## Alvos preferenciais: vivos e ainda de pé (moral > 0); se não houver, qualquer vivo.
static func standing_indexes(squad: SquadData) -> Array[int]:
	var standing: Array[int] = []
	var alive: Array[int] = []
	for i: int in squad.units.size():
		var unit: UnitInstance = squad.units[i]
		if unit.is_alive():
			alive.append(i)
			if not unit.is_broken():
				standing.append(i)
	return standing if not standing.is_empty() else alive


static func living_indexes(squad: SquadData) -> Array[int]:
	var alive: Array[int] = []
	for i: int in squad.units.size():
		if squad.units[i].is_alive():
			alive.append(i)
	return alive


static func lowest_hp_ratio_ally(squad: SquadData) -> int:
	var best: int = -1
	var best_ratio: float = 2.0
	for i: int in squad.units.size():
		var unit: UnitInstance = squad.units[i]
		if not unit.is_alive():
			continue
		var ratio: float = float(unit.hp) / float(unit.get_max_hp())
		if ratio < best_ratio:
			best_ratio = ratio
			best = i
	return best


## Todos os aliados vivos acima de `threshold_pct` do HP máximo.
static func all_allies_healthy(squad: SquadData, threshold_pct: int) -> bool:
	for unit: UnitInstance in squad.get_living_units():
		if unit.hp * 100 < unit.get_max_hp() * threshold_pct:
			return false
	return true

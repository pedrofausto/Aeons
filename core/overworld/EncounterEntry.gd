class_name EncounterEntry
extends Resource
## Uma linha da EncounterTable: qual esquadrão pode surgir, quando e com que peso.

@export var squad: SquadData                     # Modelo (com encounter_tag e patrol_route)
@export var weight: int = 10
@export_enum("any", "day", "night") var time_of_day: String = "any"
@export var min_party_level: float = 0.0         # Nível médio do jogador
@export var max_party_level: float = 99.0
@export var until_defeated: bool = false         # Chefe reativável até ser vencido (flag defeated_<id>)


func is_available(current_time: String, party_level: float) -> bool:
	return squad != null and weight > 0 \
		and (time_of_day == "any" or time_of_day == current_time) \
		and party_level >= min_party_level and party_level <= max_party_level \
		and not (until_defeated and WorldState.has_flag("defeated_%s" % squad.squad_id))

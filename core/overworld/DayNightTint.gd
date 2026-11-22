extends CanvasModulate
## Escurece o mapa à noite (afeta só o canvas do mapa, não o HUD).

const NIGHT_COLOR: Color = Color(0.55, 0.6, 0.85)


func _ready() -> void:
	EventBus.time_of_day_changed.connect(_apply)
	_apply(WorldState.time_of_day)


func _apply(time_of_day: String) -> void:
	color = NIGHT_COLOR if time_of_day == "night" else Color.WHITE

extends Node2D
class_name BattleArena25DLayout

## Canonical 3x2 perspective slot coordinates for 640x360 logical resolution.
## Slots: 0..2 = Front Row (top..bottom), 3..5 = Back Row (top..bottom).

const DEPTH_SCALES := [0.92, 1.00, 1.08]

const ALLY_SLOTS := {
	0: Vector2(236, 178),
	1: Vector2(228, 224),
	2: Vector2(220, 272),
	3: Vector2(138, 178),
	4: Vector2(126, 224),
	5: Vector2(114, 272),
}

const ENEMY_SLOTS := {
	0: Vector2(404, 178),
	1: Vector2(412, 224),
	2: Vector2(420, 272),
	3: Vector2(502, 178),
	4: Vector2(514, 224),
	5: Vector2(526, 272),
}


static func get_slot_position(slot: int, is_enemy: bool) -> Vector2:
	var table: Dictionary = ENEMY_SLOTS if is_enemy else ALLY_SLOTS
	return table.get(slot, Vector2(320, 224))


static func get_slot_scale(slot: int) -> float:
	return DEPTH_SCALES[slot % 3]

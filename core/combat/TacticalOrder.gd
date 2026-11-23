class_name TacticalOrder
extends RefCounted
## Ordens rápidas do esquadrão (Focar Líder, Focar Fraco, Poupar/Render = Pressão Moral, Defender).
## Funções puras: só alteram alvos e números. Rótulos vêm de EraConfig.order_labels.

enum Order { NONE, FOCUS_LEADER, FOCUS_WEAK, SPARE, DEFEND }  # Novos valores só no fim

const SPARE_DAMAGE_PCT: int = 40      # Golpes contidos: menos sangue...
const SPARE_MORALE_PCT: int = 200     # ...mais pressão pela rendição.
const DEFEND_DAMAGE_PCT: int = 70     # Defender: o esquadrão golpeia menos...
const DEFEND_TAKEN_PCT: int = 60      # ...e recebe bem menos dano de HP e de Moral.


static func targets_leader(order: Order) -> bool:
	return order == Order.FOCUS_LEADER


static func targets_weakest(order: Order) -> bool:
	return order == Order.FOCUS_WEAK


## Aplica a ordem de quem ataca sobre (dano de HP, dano de Moral).
static func modify(order: Order, damage: int, morale_damage: int) -> Vector2i:
	var dmg: int = damage
	var mor: int = morale_damage
	if order == Order.SPARE:
		dmg = dmg * SPARE_DAMAGE_PCT / 100
		mor = mor * SPARE_MORALE_PCT / 100
	elif order == Order.DEFEND:
		dmg = dmg * DEFEND_DAMAGE_PCT / 100
	if damage > 0:
		dmg = maxi(dmg, 1)
	return Vector2i(dmg, mor)


## Aplica a ordem de quem é atingido (Defender reduz HP e Moral perdidos).
static func mitigate(order: Order, hit: Vector2i) -> Vector2i:
	if order != Order.DEFEND:
		return hit
	return Vector2i(maxi(hit.x * DEFEND_TAKEN_PCT / 100, mini(hit.x, 1)), hit.y * DEFEND_TAKEN_PCT / 100)

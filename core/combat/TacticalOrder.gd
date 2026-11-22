class_name TacticalOrder
extends RefCounted
## Ordens rápidas do esquadrão (Focar Líder, Focar Fraco, Poupar/Render).
## Funções puras: só alteram alvos e números. Rótulos vêm de EraConfig.order_labels.

enum Order { NONE, FOCUS_LEADER, FOCUS_WEAK, SPARE }

const SPARE_DAMAGE_PCT: int = 40      # Golpes contidos: menos sangue...
const SPARE_MORALE_PCT: int = 200     # ...mais pressão pela rendição.


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
	if damage > 0:
		dmg = maxi(dmg, 1)
	return Vector2i(dmg, mor)

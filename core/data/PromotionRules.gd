class_name PromotionRules
extends RefCounted
## Regras de promoção estilo Ogre Battle: requisitos da classe de destino (nível,
## alinhamento, carisma) + item opcional (`required_item_id`), consumido ao confirmar.


## Opções de promoção que a unidade já cumpre em atributos (nível, alinhamento, carisma).
## Cada opção: { "target", "item_id", "owned", "has_item", "doctrine_ok", "forbidden", "available" }.
## Doutrina (WorldState.doctrine), flag proibitiva e item podem bloquear: a UI mostra o motivo.
static func options_for(unit: UnitInstance) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if not unit.is_alive():
		return options
	for target: UnitClassData in unit.get_eligible_promotions():
		var item_id: String = String(target.required_item_id)
		var owned: int = WorldState.count_item(item_id) if not item_id.is_empty() else 0
		var has_item: bool = item_id.is_empty() or owned > 0
		var doctrine_ok: bool = WorldState.doctrine >= target.min_doctrine and WorldState.doctrine <= target.max_doctrine
		var forbidden: bool = not target.forbidden_flag.is_empty() and WorldState.has_flag(target.forbidden_flag)
		options.append({"target": target, "item_id": item_id, "owned": owned, "has_item": has_item,
			"doctrine_ok": doctrine_ok, "forbidden": forbidden, "available": has_item and doctrine_ok and not forbidden})
	return options


static func can_promote(unit: UnitInstance, target: UnitClassData) -> bool:
	for option: Dictionary in options_for(unit):
		if option["target"] == target:
			return bool(option["available"])
	return false


## Promove consumindo 1 unidade do item exigido. Não faz nada se estiver bloqueado.
static func promote(unit: UnitInstance, target: UnitClassData) -> bool:
	if not can_promote(unit, target):
		return false
	var item_id: String = String(target.required_item_id)
	if not item_id.is_empty() and not WorldState.consume_item(item_id):
		return false
	return unit.promote(target)

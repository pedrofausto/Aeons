class_name PromotionRules
extends RefCounted
## Regras de promoção estilo Ogre Battle: requisitos da classe de destino (nível,
## alinhamento, carisma) + item opcional (`required_item_id`), consumido ao confirmar.


## Opções de promoção que a unidade já cumpre em atributos (com ou sem o item).
## Cada opção: { "target": UnitClassData, "item_id": String, "has_item": bool, "owned": int }
static func options_for(unit: UnitInstance) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if not unit.is_alive():
		return options
	for target: UnitClassData in unit.get_eligible_promotions():
		var item_id: String = String(target.required_item_id)
		var owned: int = WorldState.count_item(item_id) if not item_id.is_empty() else 0
		options.append({"target": target, "item_id": item_id, "owned": owned,
			"has_item": item_id.is_empty() or owned > 0})
	return options


static func can_promote(unit: UnitInstance, target: UnitClassData) -> bool:
	for option: Dictionary in options_for(unit):
		if option["target"] == target:
			return bool(option["has_item"])
	return false


## Promove consumindo 1 unidade do item exigido. Não faz nada se estiver bloqueado.
static func promote(unit: UnitInstance, target: UnitClassData) -> bool:
	if not can_promote(unit, target):
		return false
	var item_id: String = String(target.required_item_id)
	if not item_id.is_empty() and not WorldState.consume_item(item_id):
		return false
	return unit.promote(target)

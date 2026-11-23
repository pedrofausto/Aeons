class_name ItemData
extends Resource
## Item de campanha (inventário do ato atual em WorldState.inventory).

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var unique: bool = false
@export var march_speed_bonus_pct: int = 0       # Soma à marcha dos esquadrões do jogador
@export var reveals_night_encounters: bool = false
@export var promotion_seal: bool = false         # Selo para promoções de classes místicas

class_name FalseDefeat
extends RefCounted
## "Derrota Falsa": encerra a crônica do ato depois do clímax. Arquiva o ato no EssenceState
## (act_records + false_defeats) e segue para o próximo ato; sem próximo ato, mostra a tela
## final da crônica (EraConfig.chronicle_end_text).


## Retorna true se carregou o próximo ato (a cena do mapa deve ser recarregada).
static func trigger(map: OverworldMap) -> bool:
	var era: EraConfig = WorldState.era_config
	var end_text: String = era.chronicle_end_text if era else ""
	if era != null and not era.next_era_config.is_empty():
		EssenceState.archive_act_and_reset_visible(WorldState.current_act)
		map.get_tree().reload_current_scene()
		return true
	EssenceState.record_act(WorldState.current_act)  # Sem próximo ato: a crônica fecha aqui.
	WorldState.set_flag("chronicle_closed")
	WorldState.set_paused(true)
	map.show_banner(end_text)
	return false

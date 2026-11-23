extends Node
## Barramento global de sinais desacoplados.
## Regra: sinais SOBEM (cenas -> EventBus); chamadas diretas DESCEM (controladores -> filhos).
@warning_ignore_start("unused_signal")

# --- Camada 1: Mapa Estratégico ---
signal pause_toggled(is_paused: bool)
signal tick_advanced(day: int)
signal time_of_day_changed(time_of_day: String)
signal node_captured(node_id: String, faction_id: String)

# --- Camada 2: Combate 3x2 ---
signal battle_requested(ally_squad: SquadData, enemy_squad: SquadData, context: Dictionary)
signal battle_ended(result: Dictionary)

# --- Camada 3: Interlúdio de Presença ---
signal interlude_requested(timeline_path: String, node_id: String)
signal interlude_choice_applied(effects: Dictionary)
signal interlude_finished(timeline_path: String)

# --- Estado e Eras ---
signal world_state_changed()
signal era_loaded(config: EraConfig)
signal era_transition(from_act: int, to_act: int)
signal player_squad_formed(squad: SquadData)   # Recruta sem vaga na grade forma um esquadrão próprio

@warning_ignore_restore("unused_signal")

extends RefCounted
## Testes de Alinhamento, Doutrina e EssenceState (Derrota Falsa / transição de era).

const ACT01 := "res://eras/act_01_tianxu/EraConfig_Act01.tres"


func run(t: Node) -> void:
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	t.check("era_act01_loaded", WorldState.era_config != null and WorldState.era_config.act_number == 1
		and WorldState.era_config.map_nodes.size() == 4)

	WorldState.apply_effects({"alignment": 80, "popular_support": -90, "doctrine": 250, "resources": -9999})
	t.check("world_state_clamps", WorldState.alignment == 100 and WorldState.popular_support == 0
		and WorldState.doctrine == 100 and WorldState.resources == 0)

	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)
	WorldState.apply_effects({"alignment": 12, "doctrine": -30, "flag": "x_flag", "echo": "shared_the_rice"})
	WorldState.capture_node("linhai", "player")
	t.check("world_state_effects", WorldState.alignment == 62 and WorldState.doctrine == -30
		and WorldState.has_flag("x_flag") and WorldState.get_node_faction("linhai") == "player")

	WorldState.set_time_of_day("night")
	WorldState.completed_interludes.append("x.dtl")
	EssenceState.add_resistance_flag("protected_star_charts")
	EssenceState.mark_ephemeral_meeting("rain_cafe")
	t.check("time_of_day_and_interludes", WorldState.time_of_day == "night" and WorldState.era_config.reality_layer == "PHYSICAL_WAR")

	# Derrota Falsa: arquiva o Ato I e reinicia o estado visível para o Ato II
	var old_theme: Theme = WorldState.era_config.ui_theme
	EssenceState.archive_act_and_reset_visible(1)
	t.check("essence_archives_act", EssenceState.completed_acts == [1]
		and EssenceState.alignment_history.get(1) == 62 and EssenceState.doctrine_history.get(1) == -30)
	t.check("essence_keeps_echoes", "shared_the_rice" in EssenceState.philosophical_echoes
		and "protected_star_charts" in EssenceState.aeon_resistance_flags and "rain_cafe" in EssenceState.ephemeral_meetings_seen)
	t.check("world_state_resets_time_and_interludes", WorldState.time_of_day == "day" and WorldState.completed_interludes.is_empty())
	t.check("world_state_reset_visible", WorldState.current_act == 2 and WorldState.alignment == 50
		and WorldState.doctrine == 0 and WorldState.captured_nodes.is_empty() and WorldState.act_echoes.is_empty())
	t.check("era_act02_labels", WorldState.era_config.act_number == 2 and WorldState.era_config.resource_label == "Prata")
	t.check("era_act02_theme_swapped", WorldState.era_config.ui_theme != old_theme
		and (t.get_tree().root as Window).theme == WorldState.era_config.ui_theme)

	# Restaura o Ato I para as próximas suítes
	EssenceState.reset_all()
	WorldState.reset_visible(1)
	WorldState.load_era(ACT01)

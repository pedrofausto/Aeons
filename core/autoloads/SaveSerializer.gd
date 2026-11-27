class_name SaveSerializer
extends RefCounted
## Serialização e restauração determinística de WorldState e EssenceState para JSON.


static func serialize_world() -> Dictionary:
	var inv: Array[String] = []
	for item: ItemData in WorldState.inventory:
		if item != null and not item.resource_path.is_empty():
			inv.append(item.resource_path)
	var squads_arr: Array[Dictionary] = []
	for squad: SquadData in WorldState.player_squads:
		squads_arr.append(_serialize_squad(squad))
	return {
		"current_act": WorldState.current_act, "alignment": WorldState.alignment,
		"popular_support": WorldState.popular_support, "doctrine": WorldState.doctrine,
		"resources": WorldState.resources, "day_count": WorldState.day_count,
		"time_of_day": WorldState.time_of_day, "captured_nodes": WorldState.captured_nodes,
		"active_flags": WorldState.active_flags, "act_echoes": WorldState.act_echoes,
		"completed_interludes": WorldState.completed_interludes,
		"unlocked_classes": WorldState.unlocked_classes, "siege": WorldState.siege,
		"liberation_methods": WorldState.liberation_methods,
		"faction_trust": WorldState.faction_trust, "inventory": inv, "player_squads": squads_arr,
	}


static func _serialize_squad(squad: SquadData) -> Dictionary:
	var units_arr: Array[Dictionary] = []
	for u: UnitInstance in squad.units:
		units_arr.append({
			"class_path": u.class_data.resource_path if u.class_data else "",
			"unit_name": u.unit_name, "level": u.level, "experience": u.experience,
			"alignment": u.alignment, "charisma": u.charisma, "slot": u.slot,
			"is_leader": u.is_leader, "hp": u.hp, "morale": u.morale,
			"weapon": u.equipped_weapon.resource_path if u.equipped_weapon else "",
			"armor": u.equipped_armor.resource_path if u.equipped_armor else "",
		})
	return {
		"squad_id": squad.squad_id, "display_name": squad.display_name,
		"faction": squad.faction, "current_node_id": squad.current_node_id,
		"fatigue": squad.fatigue, "units": units_arr,
	}


static func restore_world(w: Dictionary) -> void:
	WorldState.current_act = int(w.get("current_act", WorldState.current_act))
	WorldState.alignment = int(w.get("alignment", WorldState.DEFAULT_ALIGNMENT))
	WorldState.popular_support = int(w.get("popular_support", WorldState.DEFAULT_SUPPORT))
	WorldState.doctrine = int(w.get("doctrine", 0))
	WorldState.resources = int(w.get("resources", WorldState.DEFAULT_RESOURCES))
	WorldState.day_count = int(w.get("day_count", 1))
	WorldState.time_of_day = String(w.get("time_of_day", "day"))
	WorldState.captured_nodes = (w.get("captured_nodes", {}) as Dictionary).duplicate(true)
	WorldState.active_flags = (w.get("active_flags", {}) as Dictionary).duplicate(true)
	WorldState.act_echoes.assign(w.get("act_echoes", []))
	WorldState.completed_interludes.assign(w.get("completed_interludes", []))
	WorldState.unlocked_classes.assign(w.get("unlocked_classes", []))
	WorldState.siege = (w.get("siege", {}) as Dictionary).duplicate(true)
	WorldState.liberation_methods = (w.get("liberation_methods", {}) as Dictionary).duplicate(true)
	WorldState.faction_trust = (w.get("faction_trust", {}) as Dictionary).duplicate(true)
	WorldState.inventory.clear()
	for p: Variant in w.get("inventory", []):
		var item := load(String(p)) as ItemData
		if item != null:
			WorldState.inventory.append(item)
	WorldState.player_squads.clear()
	for sd: Variant in w.get("player_squads", []):
		WorldState.player_squads.append(_restore_squad(sd as Dictionary))
	WorldState._notify()


static func _restore_squad(sd: Dictionary) -> SquadData:
	var sq := SquadData.new()
	sq.squad_id = String(sd.get("squad_id", ""))
	sq.display_name = String(sd.get("display_name", ""))
	sq.faction = String(sd.get("faction", "player"))
	sq.current_node_id = String(sd.get("current_node_id", ""))
	sq.fatigue = int(sd.get("fatigue", 0))
	for ud: Variant in sd.get("units", []):
		var d := ud as Dictionary
		var cls := load(String(d.get("class_path", ""))) as UnitClassData
		if cls == null:
			continue
		var u := UnitInstance.create(cls, String(d.get("unit_name", "")), int(d.get("level", 1)),
			int(d.get("slot", 0)), bool(d.get("is_leader", false)),
			int(d.get("alignment", 50)), int(d.get("charisma", 50)))
		u.experience = int(d.get("experience", 0))
		u.hp = int(d.get("hp", u.get_max_hp()))
		u.morale = int(d.get("morale", u.get_max_morale()))
		if not String(d.get("weapon", "")).is_empty():
			u.equipped_weapon = load(String(d["weapon"])) as ItemData
		if not String(d.get("armor", "")).is_empty():
			u.equipped_armor = load(String(d["armor"])) as ItemData
		sq.units.append(u)
	return sq


static func serialize_essence() -> Dictionary:
	return {
		"completed_acts": EssenceState.completed_acts, "alignment_history": EssenceState.alignment_history,
		"doctrine_history": EssenceState.doctrine_history, "philosophical_echoes": EssenceState.philosophical_echoes,
		"aeon_resistance_flags": EssenceState.aeon_resistance_flags,
		"ephemeral_meetings_seen": EssenceState.ephemeral_meetings_seen,
		"act_records": EssenceState.act_records, "false_defeats": EssenceState.false_defeats,
		"echo_values": EssenceState.echo_values, "decisions": EssenceState.decisions,
		"protagonist_profile": EssenceState.protagonist_profile,
	}


static func restore_essence(e: Dictionary) -> void:
	EssenceState.reset_all()
	for a: Variant in e.get("completed_acts", []):
		EssenceState.completed_acts.append(int(a))
	EssenceState.alignment_history = (e.get("alignment_history", {}) as Dictionary).duplicate(true)
	EssenceState.doctrine_history = (e.get("doctrine_history", {}) as Dictionary).duplicate(true)
	EssenceState.philosophical_echoes.assign(e.get("philosophical_echoes", []))
	EssenceState.aeon_resistance_flags.assign(e.get("aeon_resistance_flags", []))
	EssenceState.ephemeral_meetings_seen.assign(e.get("ephemeral_meetings_seen", []))
	EssenceState.act_records = (e.get("act_records", {}) as Dictionary).duplicate(true)
	EssenceState.false_defeats.assign(e.get("false_defeats", []))
	EssenceState.echo_values = (e.get("echo_values", {}) as Dictionary).duplicate(true)
	EssenceState.decisions = (e.get("decisions", {}) as Dictionary).duplicate(true)
	EssenceState.protagonist_profile = (e.get("protagonist_profile", {}) as Dictionary).duplicate(true)

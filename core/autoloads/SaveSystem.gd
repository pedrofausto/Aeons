extends Node
## Persistência multi-slot (WorldState + EssenceState) e configurações em user://.

const SAVE_DIR := "user://saves"
const SETTINGS_PATH := "user://settings.cfg"
const SLOT_COUNT := 4  # 0 = Autosave, 1..3 = Slots Manuais

var settings: Dictionary = {
	"fullscreen": false,
	"master_volume": 1.0,
	"music_volume": 0.85,
	"sfx_volume": 0.90,
	"battle_speed": "normal",
	"reduce_flashes": false,
}


func _ready() -> void:
	load_settings()
	apply_settings()


func get_battle_step_seconds() -> float:
	return 0.10 if String(settings.get("battle_speed", "normal")) == "fast" else 0.25


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for key: String in settings.keys():
		settings[key] = cfg.get_value("options", key, settings[key])


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key: String in settings.keys():
		cfg.set_value("options", key, settings[key])
	cfg.save(SETTINGS_PATH)
	apply_settings()


func apply_settings() -> void:
	if not OS.has_feature("web"):
		var want_fs := bool(settings.get("fullscreen", false))
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if want_fs else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	_apply_bus_volume(&"Master", float(settings.get("master_volume", 1.0)))
	_apply_bus_volume(&"Music", float(settings.get("music_volume", 0.85)))
	_apply_bus_volume(&"SFX", float(settings.get("sfx_volume", 0.90)))


func _apply_bus_volume(bus_name: StringName, linear_val: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var clamped := clampf(linear_val, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, clamped <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(clamped, 0.001)))


func _slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, clampi(slot, 0, SLOT_COUNT - 1)]


func list_slots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot: int in SLOT_COUNT:
		out.append(read_slot_meta(slot))
	return out


func read_slot_meta(slot: int) -> Dictionary:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {"slot": slot, "empty": true}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return {"slot": slot, "empty": true}
	var meta: Dictionary = (parsed as Dictionary).get("meta", {})
	meta["slot"] = slot
	meta["empty"] = false
	return meta


func has_any_save() -> bool:
	for slot: int in SLOT_COUNT:
		if FileAccess.file_exists(_slot_path(slot)):
			return true
	return false


func get_latest_slot() -> int:
	var best_slot: int = -1
	var best_unix: int = -1
	for meta: Dictionary in list_slots():
		if not bool(meta.get("empty", true)) and int(meta.get("unix_time", 0)) >= best_unix:
			best_unix = int(meta.get("unix_time", 0))
			best_slot = int(meta["slot"])
	return best_slot


func delete_slot(slot: int) -> void:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func save_slot(slot: int) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var leader_name := ""
	if not WorldState.player_squads.is_empty() and WorldState.player_squads[0].get_leader() != null:
		leader_name = WorldState.player_squads[0].get_leader().unit_name
	var payload := {
		"meta": {
			"slot": slot,
			"unix_time": int(Time.get_unix_time_from_system()),
			"saved_at": Time.get_datetime_string_from_system(false, true),
			"act_number": WorldState.current_act,
			"era_title": WorldState.era_config.era_title if WorldState.era_config else "Ato %d" % WorldState.current_act,
			"day_count": WorldState.day_count,
			"resources": WorldState.resources,
			"leader_name": leader_name,
			"era_config_path": WorldState.era_config.resource_path if WorldState.era_config else "",
		},
		"world": SaveSerializer.serialize_world(),
		"essence": SaveSerializer.serialize_essence(),
	}
	var f := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	return true


func load_slot(slot: int) -> bool:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return false
	var data := parsed as Dictionary
	var meta: Dictionary = data.get("meta", {})
	var era_path := String(meta.get("era_config_path", ""))
	if era_path.is_empty():
		era_path = ProjectSettings.get_setting(WorldState.START_ERA_SETTING, "")
	SaveSerializer.restore_essence(data.get("essence", {}))
	WorldState.reset_visible(int(meta.get("act_number", 1)))
	if not era_path.is_empty():
		WorldState.load_era(era_path)
	SaveSerializer.restore_world(data.get("world", {}))
	return true

extends Node

const LEVELS_PATH := "res://data/levels.json"
const SAVE_PATH := "user://save.json"
const FADE_TIME := 0.25
const LEVEL_SAVE_VERSION := 4
const INSERTED_PAINTING_LEVELS := 12
const LEVEL_ID_REMAP_RANGES := [
	[1, 12, 1],
	[13, 24, 51],
	[37, 12, 101],
	[49, 12, 151],
	[61, 12, 201],
	[73, 9, 251],
	[82, 9, 301],
	[91, 6, 351],
	[97, 6, 401],
	[103, 6, 451],
]
const OLD_BOSS_COMPLETIONS := [
	[12, 50], [36, 100], [48, 150], [60, 200], [72, 250],
	[81, 300], [90, 350], [96, 400], [102, 450], [108, 500],
]
const LEVEL_ID_500_TO_200_RANGES := [
	[1, 50, 1], [51, 50, 21], [101, 50, 41], [151, 50, 61], [201, 50, 81],
	[251, 50, 101], [301, 50, 121], [351, 50, 141], [401, 50, 161], [451, 50, 181],
]

var levels: Array = []
var worlds: Array = []
var current_level := 0
var has_current_level := false
var daily_level := 0
var stars := {}
var daily_completed: Dictionary = {}
var mission_progress: Dictionary = {}
var mission_lamps := 0
var daily_mode := false
var daily_date := ""
var temporary_unlock_all := false
var settings := {"music": true, "sfx": true, "vibration": true, "seen_howto": false}
var sfx := Sfx.new()

var _fade := ColorRect.new()
var _busy := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BG)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LEVELS_PATH))
	levels = data["levels"]
	worlds = data["worlds"]
	_read()
	add_child(sfx)
	sfx.apply(settings)

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade.color = Color(Palette.BG, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func go(path: String) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await out.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	await back.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func stars_for(id: int) -> int:
	return int(stars.get(str(id), 0))


func is_unlocked(id: int) -> bool:
	return temporary_unlock_all or id == 1 or stars_for(id - 1) > 0


func set_current_level(index: int) -> void:
	if levels.is_empty():
		return
	var safe_index := clampi(index, 0, levels.size() - 1)
	var changed := not has_current_level or current_level != safe_index
	current_level = safe_index
	has_current_level = true
	if changed:
		_write()


func record(id: int, earned: int) -> void:
	var changed := false
	if earned > stars_for(id):
		stars[str(id)] = earned
		changed = true
	if _mark_daily_mission("level", 1):
		changed = true
	if changed:
		_write()


func start_daily_challenge() -> void:
	var date := Time.get_date_dict_from_system()
	daily_date = "%04d-%02d-%02d" % [int(date["year"]), int(date["month"]), int(date["day"])]
	var day_seed := int(date["year"]) * 372 + int(date["month"]) * 31 + int(date["day"])
	daily_level = posmod(day_seed, levels.size())
	daily_mode = true


func is_daily_completed(date: String = "") -> bool:
	var key := date if not date.is_empty() else _today_key()
	return bool(daily_completed.get(key, false))


func record_daily_completion() -> void:
	if daily_date.is_empty():
		daily_date = _today_key()
	daily_completed[daily_date] = true
	_mark_daily_mission("daily", 2)
	_write()


func missions_for_today() -> Dictionary:
	var today := _today_key()
	var saved: Dictionary = mission_progress.get(today, {})
	return {
		"level": bool(saved.get("level", false)),
		"daily": bool(saved.get("daily", daily_completed.get(today, false))),
	}


func _mark_daily_mission(mission: String, reward: int) -> bool:
	var today := _today_key()
	var status: Dictionary = mission_progress.get(today, {"level": false, "daily": false})
	if bool(status.get(mission, false)):
		return false
	status[mission] = true
	mission_progress[today] = status
	mission_lamps += reward
	return true


func total_lamps() -> int:
	var total := mission_lamps
	for level_stars in stars.values():
		total += int(level_stars)
	return total


func visual_theme_unlocked(theme_id: int) -> bool:
	match theme_id:
		0:
			return true
		1:
			return total_lamps() >= 20
		2:
			return total_lamps() >= 60
		3:
			return total_lamps() >= 120
	return false


func visual_theme() -> int:
	var selected := int(settings.get("visual_theme", 0))
	return selected if visual_theme_unlocked(selected) else 0


func select_visual_theme(theme_id: int) -> void:
	if not visual_theme_unlocked(theme_id):
		return
	settings["visual_theme"] = theme_id
	_write()


func set_setting(key: String, value: bool) -> void:
	settings[key] = value
	_write()
	sfx.apply(settings)


func _read() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		stars = parsed.get("stars", {})
		daily_completed = parsed.get("daily_completed", {})
		mission_progress = parsed.get("mission_progress", {})
		mission_lamps = int(parsed.get("mission_lamps", 0))
		current_level = int(parsed.get("current_level", current_level))
		has_current_level = bool(parsed.get("has_current_level", false))
		settings.merge(parsed.get("settings", {}), true)
		var save_version := int(parsed.get("level_save_version", 1))
		if save_version < LEVEL_SAVE_VERSION:
			if save_version < 2:
				var shifted_stars := {}
				for key in stars:
					var id := int(key)
					var shifted_id := id + INSERTED_PAINTING_LEVELS if id >= 25 else id
					shifted_stars[str(shifted_id)] = stars[key]
				stars = shifted_stars
				if has_current_level and current_level + 1 >= 25:
					current_level += INSERTED_PAINTING_LEVELS
			if save_version < 3:
				var remapped_stars := {}
				for key in stars:
					var new_id := _remap_legacy_level_id(int(key))
					remapped_stars[str(new_id)] = stars[key]
				for boss_completion in OLD_BOSS_COMPLETIONS:
					var old_boss_stars := int(stars.get(str(boss_completion[0]), 0))
					if old_boss_stars > 0:
						var new_boss_id := str(boss_completion[1])
						remapped_stars[new_boss_id] = maxi(int(remapped_stars.get(new_boss_id, 0)), old_boss_stars)
				stars = remapped_stars
				if has_current_level:
					current_level = _remap_legacy_level_id(current_level + 1) - 1
			if save_version < 4:
				var reduced_stars := {}
				for key in stars:
					var reduced_id := _remap_expanded_level_id(int(key))
					if reduced_id > 0:
						var reduced_key := str(reduced_id)
						reduced_stars[reduced_key] = maxi(int(reduced_stars.get(reduced_key, 0)), int(stars[key]))
				stars = reduced_stars
				if has_current_level:
					current_level = _remap_expanded_current_level(current_level + 1) - 1
			_write()


func _remap_legacy_level_id(level_id: int) -> int:
	for remap in LEVEL_ID_REMAP_RANGES:
		var old_start := int(remap[0])
		var count := int(remap[1])
		if level_id >= old_start and level_id < old_start + count:
			return int(remap[2]) + level_id - old_start
	return level_id


func _remap_expanded_level_id(level_id: int) -> int:
	for remap in LEVEL_ID_500_TO_200_RANGES:
		var old_start := int(remap[0])
		var count := int(remap[1])
		if level_id >= old_start and level_id < old_start + count:
			var phase := level_id - old_start + 1
			if phase <= 20 or phase == 50:
				return int(remap[2]) + mini(phase, 20) - 1
			return 0
	return level_id


func _remap_expanded_current_level(level_id: int) -> int:
	for remap in LEVEL_ID_500_TO_200_RANGES:
		var old_start := int(remap[0])
		var count := int(remap[1])
		if level_id >= old_start and level_id < old_start + count:
			var phase := level_id - old_start + 1
			return int(remap[2]) + mini(phase, 20) - 1
	return clampi(level_id, 1, levels.size())


func _today_key() -> String:
	var date := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(date["year"]), int(date["month"]), int(date["day"])]


func _write() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"level_save_version": LEVEL_SAVE_VERSION, "stars": stars, "daily_completed": daily_completed, "mission_progress": mission_progress, "mission_lamps": mission_lamps, "current_level": current_level, "has_current_level": has_current_level, "settings": settings}))

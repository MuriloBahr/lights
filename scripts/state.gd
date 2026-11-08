extends Node

const LEVELS_PATH := "res://data/levels.json"
const SAVE_PATH := "user://save.json"

var levels: Array = []
var current_level := 0
var stars := {}
var settings := {"music": true, "sfx": true, "vibration": true}
var sfx := Sfx.new()


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BG)
	levels = JSON.parse_string(FileAccess.get_file_as_string(LEVELS_PATH))["levels"]
	_read()
	add_child(sfx)
	sfx.apply(settings)


func stars_for(id: int) -> int:
	return int(stars.get(str(id), 0))


func is_unlocked(id: int) -> bool:
	return id == 1 or stars_for(id - 1) > 0


func record(id: int, earned: int) -> void:
	if earned > stars_for(id):
		stars[str(id)] = earned
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
		settings.merge(parsed.get("settings", {}), true)


func _write() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"stars": stars, "settings": settings}))
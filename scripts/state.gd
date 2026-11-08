extends Node

const LEVELS_PATH := "res://data/levels.json"
const SAVE_PATH := "user://save.json"

var levels: Array = []
var current_level := 0
var stars := {}


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BG)
	levels = JSON.parse_string(FileAccess.get_file_as_string(LEVELS_PATH))["levels"]
	_read()


func stars_for(id: int) -> int:
	return int(stars.get(str(id), 0))


func is_unlocked(id: int) -> bool:
	return id == 1 or stars_for(id - 1) > 0


func record(id: int, earned: int) -> void:
	if earned > stars_for(id):
		stars[str(id)] = earned
		_write()


func _read() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		stars = parsed.get("stars", {})


func _write() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"stars": stars}))
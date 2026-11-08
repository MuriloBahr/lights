extends Node

const LEVELS_PATH := "res://data/levels.json"
const SAVE_PATH := "user://save.json"
const FADE_TIME := 0.25

var levels: Array = []
var current_level := 0
var stars := {}
var settings := {"music": true, "sfx": true, "vibration": true}
var sfx := Sfx.new()

var _fade := ColorRect.new()
var _busy := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BG)
	levels = JSON.parse_string(FileAccess.get_file_as_string(LEVELS_PATH))["levels"]
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
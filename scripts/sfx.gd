class_name Sfx
extends Node

var vibration := true
var _tap: AudioStreamPlayer
var _win: AudioStreamPlayer


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_tap = _player("res://assets/sfx/tap.wav")
	_win = _player("res://assets/sfx/win.wav")


func apply(settings: Dictionary) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not settings["music"])
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not settings["sfx"])
	vibration = settings["vibration"]


func tap() -> void:
	_tap.pitch_scale = randf_range(0.92, 1.12)
	_tap.play()
	_buzz(15)


func win() -> void:
	_win.play()
	_buzz(120)


func _buzz(ms: int) -> void:
	if vibration:
		Input.vibrate_handheld(ms)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _player(path: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.bus = "SFX"
	p.max_polyphony = 4
	add_child(p)
	return p


func ding(step: int) -> void:
	_tap.pitch_scale = 1.0 + 0.3 * step
	_tap.play()
	_buzz(20)
class_name Sfx
extends Node

const MUSIC_PATH := "res://assets/music/theme.mp3"
const MUSIC_DB := -20.0
const GAME_DUCK_DB := 8.0

var vibration := true
var _tap: AudioStreamPlayer
var _win: AudioStreamPlayer
var _click: AudioStreamPlayer
var _start: AudioStreamPlayer
var _music: AudioStreamPlayer
var _music_tween: Tween
var _music_target := MUSIC_DB


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_tap = _player("res://assets/sfx/tap.wav")
	_win = _player("res://assets/sfx/win.wav")
	_click = _player("res://assets/sfx/click.wav")
	_click.volume_db = -4.0
	_start = _player("res://assets/sfx/start.wav")
	_start_music()


func apply(settings: Dictionary) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not settings["music"])
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not settings["sfx"])
	vibration = settings["vibration"]


func duck(on: bool) -> void:
	_music_target = MUSIC_DB - (GAME_DUCK_DB if on else 0.0)
	if _music:
		_fade_music(_music_target, 0.8 if _music.volume_db > -40.0 else 3.0)


func tap() -> void:
	_tap.pitch_scale = randf_range(0.96, 1.04)
	_tap.play()
	_buzz(15)


func ding(step: int) -> void:
	_tap.pitch_scale = 1.0 + 0.3 * step
	_tap.play()
	_buzz(20)


func click() -> void:
	_click.play()
	_buzz(10)


func start() -> void:
	_start.pitch_scale = 1.0
	_start.play()
	_buzz(30)


func enter() -> void:
	_start.pitch_scale = 1.3
	_start.play()
	_buzz(15)


func win() -> void:
	_win.play()
	_buzz(120)
	_dip()


func _notification(what: int) -> void:
	if not _music:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_music.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_music.stream_paused = false


func _start_music() -> void:
	if not ResourceLoader.exists(MUSIC_PATH):
		return
	var stream: AudioStream = load(MUSIC_PATH)
	stream.set("loop", true)
	_music = AudioStreamPlayer.new()
	_music.stream = stream
	_music.bus = "Music"
	_music.volume_db = -60.0
	add_child(_music)
	_music.play()
	_fade_music(_music_target, 3.0)


func _fade_music(db: float, seconds: float) -> void:
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", db, seconds)


func _dip() -> void:
	if not _music:
		return
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", _music_target - 6.0, 0.15)
	_music_tween.tween_interval(1.4)
	_music_tween.tween_property(_music, "volume_db", _music_target, 1.0)


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
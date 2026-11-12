class_name Sfx
extends Node

const MUSIC_PATH := "res://assets/music/theme.mp3"
const MUSIC_DB := -10.0
const GAME_DUCK_DB := 8.0
const BOSS_THEME_STREAMS := {
	1: preload("res://assets/music/boss_sonequinha.mp3"),
	2: preload("res://assets/music/boss_coruja.mp3"),
	3: preload("res://assets/music/boss_nuvem.mp3"),
}

var vibration := true
var _tap: AudioStreamPlayer
var _win: AudioStreamPlayer
var _click: AudioStreamPlayer
var _start: AudioStreamPlayer
var _music: AudioStreamPlayer
var _music_tween: Tween
var _music_target := MUSIC_DB
var _glow: AudioStreamPlayer
var _boss_defeat: AudioStreamPlayer
var _boss_theme: AudioStreamPlayer
var _boss_theme_tween: Tween


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_tap = _player("res://assets/sfx/tap.wav")
	_win = _player("res://assets/sfx/win.wav")
	_click = _player("res://assets/sfx/click.wav")
	_click.volume_db = -4.0
	_start = _player("res://assets/sfx/start.wav")
	_start_music()
	_glow = _player("res://assets/sfx/enter_glow.wav")
	_glow.volume_db = -3.0
	_boss_defeat = AudioStreamPlayer.new()
	_boss_defeat.stream = _make_boss_defeat_sound()
	_boss_defeat.bus = "SFX"
	_boss_defeat.volume_db = -1.5
	_boss_defeat.max_polyphony = 1
	add_child(_boss_defeat)
	_boss_theme = AudioStreamPlayer.new()
	_boss_theme.bus = "Music"
	_boss_theme.volume_db = -60.0
	add_child(_boss_theme)


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


func toggle(is_lit: bool) -> void:
	_tap.pitch_scale = randf_range(1.08, 1.16) if is_lit else randf_range(0.82, 0.9)
	_tap.play()
	_buzz(12)


func combo(streak: int) -> void:
	_glow.pitch_scale = clampf(0.9 + streak * 0.06, 0.9, 1.35)
	_glow.play()
	if streak >= 3:
		_buzz(24)


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


func boss_defeat() -> void:
	_boss_defeat.play()
	_buzz(180)
	_dip()


func boss_theme(world_id: int) -> void:
	var source_stream: AudioStream = BOSS_THEME_STREAMS.get(world_id)
	if source_stream == null:
		stop_boss_theme()
		return
	if is_instance_valid(_boss_theme_tween) and _boss_theme_tween.is_running():
		_boss_theme_tween.kill()
	_boss_theme.stop()
	var stream := source_stream.duplicate() as AudioStream
	stream.set("loop", true)
	_boss_theme.stream = stream
	_boss_theme.volume_db = -28.0
	_boss_theme.play()
	if is_instance_valid(_music):
		if is_instance_valid(_music_tween) and _music_tween.is_running():
			_music_tween.kill()
		_music_tween = create_tween()
		_music_tween.tween_property(_music, "volume_db", -48.0, 0.55)
	_boss_theme_tween = create_tween()
	_boss_theme_tween.tween_property(_boss_theme, "volume_db", -9.0, 0.7)


func set_main_track(world_id: int) -> void:
	if not is_instance_valid(_music):
		return
	var source_stream: AudioStream = BOSS_THEME_STREAMS.get(world_id) if world_id > 0 else null
	if source_stream == null:
		source_stream = load(MUSIC_PATH)
	if is_instance_valid(_boss_theme_tween) and _boss_theme_tween.is_running():
		_boss_theme_tween.kill()
	_boss_theme.stop()
	_boss_theme.volume_db = -48.0
	if is_instance_valid(_music_tween) and _music_tween.is_running():
		_music_tween.kill()
	var stream := source_stream.duplicate() as AudioStream
	stream.set("loop", true)
	_music.stream = stream
	_music.volume_db = -36.0
	_music.play()
	_fade_music(_music_target, 0.65)


func stop_boss_theme() -> void:
	if not is_instance_valid(_boss_theme):
		return
	if not _boss_theme.playing and _boss_theme.volume_db <= -47.0:
		return
	if is_instance_valid(_boss_theme_tween) and _boss_theme_tween.is_running():
		_boss_theme_tween.kill()
	if is_instance_valid(_music_tween) and _music_tween.is_running():
		_music_tween.kill()
	_boss_theme_tween = create_tween()
	_boss_theme_tween.set_parallel(true)
	_boss_theme_tween.tween_property(_boss_theme, "volume_db", -48.0, 0.35)
	if is_instance_valid(_music):
		_boss_theme_tween.tween_property(_music, "volume_db", _music_target, 0.5)
	_boss_theme_tween.set_parallel(false)
	_boss_theme_tween.tween_callback(_finish_boss_theme)


func _finish_boss_theme() -> void:
	_boss_theme.stop()


func glow() -> void:
	_glow.play()
	_buzz(15)


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
	if not _music or (_boss_theme and _boss_theme.playing):
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


func _make_boss_defeat_sound() -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * 0.9)
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	var low_phase := 0.0
	var bell_phase := 0.0
	var sparkle_phase := 0.0
	var high_phase := 0.0
	for i in sample_count:
		var t := float(i) / sample_rate
		var low_frequency := lerpf(250.0, 130.0, clampf(t / 0.42, 0.0, 1.0))
		low_phase += TAU * low_frequency / sample_rate
		var low_envelope := exp(-t * 5.5)
		var low_note := sin(low_phase) * 0.24 * low_envelope
		var bell_note := 0.0
		if t >= 0.18:
			bell_phase += TAU * 660.0 / sample_rate
			bell_note = sin(bell_phase) * 0.16 * exp(-(t - 0.18) * 8.0)
		var sparkle_note := 0.0
		if t >= 0.38:
			sparkle_phase += TAU * 990.0 / sample_rate
			sparkle_note = sin(sparkle_phase) * 0.1 * exp(-(t - 0.38) * 10.0)
		var high_note := 0.0
		if t >= 0.48:
			high_phase += TAU * 1320.0 / sample_rate
			high_note = sin(high_phase) * 0.045 * exp(-(t - 0.48) * 12.0)
		var sample := clampf((low_note + bell_note + sparkle_note + high_note) * 0.85, -1.0, 1.0)
		samples.encode_s16(i * 2, int(sample * 32767.0))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = sample_rate
	sound.stereo = false
	sound.data = samples
	return sound

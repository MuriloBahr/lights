extends Control

var bulbs: Array[Bulb] = []
var _step := 0
var _settings: SettingsPanel
var _timer: Timer
var _starting := false
var _margin: MarginContainer
var _bulb_row: HBoxContainer
var _title_label: RichTextLabel
var _play_button: Button
var _gear_button: GearButton
var _initials_timer: Timer
var _initials_taps := 0
var _showing_initials := false


func _ready() -> void:
	State.sfx.duck(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := WorldBackdrop.new()
	backdrop.setup(7)
	add_child(backdrop)
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_margin.add_child(box)

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	top.custom_minimum_size.y = 72
	_gear_button = GearButton.new()
	_gear_button.custom_minimum_size = Vector2(64, 64)
	_gear_button.pressed.connect(_open_settings)
	top.add_child(_gear_button)
	box.add_child(top)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(center)
	var identity := VBoxContainer.new()
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	identity.add_theme_constant_override("separation", 12)
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(identity)
	_bulb_row = _make_bulb_row()
	identity.add_child(_bulb_row)
	_title_label = _title()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_title_label.gui_input.connect(_on_title_gui_input)
	identity.add_child(_title_label)
	identity.add_child(Ui.label("apague todas as luzes", 26, Palette.BASE))

	_play_button = Ui.button("Jogar", Palette.BULBS[0], 40)
	_play_button.pressed.connect(_play)
	_play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(_play_button)

	var bottom := Control.new()
	bottom.custom_minimum_size = Vector2(0, 20)
	box.add_child(bottom)
	_initials_timer = Timer.new()
	_initials_timer.one_shot = true
	_initials_timer.wait_time = 2.0
	_initials_timer.timeout.connect(_reset_initials_taps)
	add_child(_initials_timer)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func _make_bulb_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	for i in 5:
		var b := Bulb.new()
		b.custom_minimum_size = Vector2(88, 88)
		b.color = Palette.BULBS[i]
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(b)
		bulbs.append(b)

	_timer = Timer.new()
	_timer.wait_time = 0.35
	_timer.autostart = true
	_timer.timeout.connect(_tick)
	add_child(_timer)
	return row


func _apply_responsive_layout() -> void:
	if not is_instance_valid(_margin):
		return
	var viewport_size := get_viewport_rect().size
	var horizontal_margin := int(clampf(viewport_size.x * 0.06, 16.0, 32.0))
	var vertical_margin := int(clampf(viewport_size.y * 0.04, 16.0, 32.0))
	for side in ["left", "right"]:
		_margin.add_theme_constant_override("margin_" + side, horizontal_margin)
	for side in ["top", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, vertical_margin)
	var bulb_size := minf(88.0, (viewport_size.x - horizontal_margin * 2.0 - 16.0) / 5.0)
	for bulb in bulbs:
		bulb.custom_minimum_size = Vector2(bulb_size, bulb_size)
	_title_label.add_theme_font_size_override("normal_font_size", int(clampf(viewport_size.x * 0.14, 44.0, 72.0)))
	_gear_button.custom_minimum_size = Vector2(64, 64)
	_play_button.custom_minimum_size.y = clampf(viewport_size.y * 0.09, 64.0, 88.0)


func _title() -> RichTextLabel:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.add_theme_font_size_override("normal_font_size", 72)
	var text := "[center]"
	var i := 0
	for ch in "Lights":
		if ch == " ":
			text += " "
			continue
		text += "[color=#%s]%s[/color]" % [Palette.BULBS[i % Palette.BULBS.size()].to_html(false), ch]
		i += 1
	t.text = text + "[/center]"
	return t


func _tick() -> void:
	var n := bulbs.size()
	var i := _step % (2 * n)
	bulbs[i % n].set_lit(i < n)
	_step += 1


func _on_title_gui_input(event: InputEvent) -> void:
	if _starting or _showing_initials:
		return
	var tap := event as InputEventMouseButton
	if tap == null or not tap.pressed or tap.button_index != MOUSE_BUTTON_LEFT:
		return
	_initials_taps += 1
	_initials_timer.start()
	if _initials_taps >= 5:
		_initials_timer.stop()
		_initials_taps = 0
		_show_initials_easter_egg()


func _reset_initials_taps() -> void:
	_initials_taps = 0


func _show_initials_easter_egg() -> void:
	_showing_initials = true
	_title_label.modulate.a = 0.0
	var reveal := RichTextLabel.new()
	reveal.bbcode_enabled = true
	reveal.fit_content = true
	reveal.scroll_active = false
	reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal.add_theme_font_size_override("normal_font_size", 58)
	reveal.text = "[center][color=#%s]M[/color]  [color=#%s]♥[/color]  [color=#%s]K[/color][/center]" % [Palette.BULBS[1].to_html(false), Palette.BULBS[0].to_html(false), Palette.BULBS[2].to_html(false)]
	reveal.size = Vector2(minf(size.x - 32.0, 340.0), 88.0)
	var title_center := _title_label.get_global_rect().get_center() - get_global_rect().position
	reveal.position = title_center - reveal.size / 2.0
	reveal.pivot_offset = reveal.size / 2.0
	reveal.scale = Vector2(0.55, 0.55)
	reveal.modulate.a = 0.0
	reveal.z_index = 15
	add_child(reveal)
	for i in bulbs.size():
		bulbs[i].play_effect(float(i) * 0.06)
	var appear := create_tween().set_parallel(true)
	appear.tween_property(reveal, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	appear.tween_property(reveal, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(1.8).timeout
	var disappear := create_tween().set_parallel(true)
	disappear.tween_property(reveal, "scale", Vector2(0.8, 0.8), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	disappear.tween_property(reveal, "modulate:a", 0.0, 0.22)
	await disappear.finished
	_title_label.modulate.a = 1.0
	reveal.queue_free()
	_showing_initials = false


func _play() -> void:
	if _starting:
		return
	_starting = true
	_timer.stop()
	State.sfx.start()
	var transition := Control.new()
	transition.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition.mouse_filter = Control.MOUSE_FILTER_STOP
	transition.z_index = 20
	add_child(transition)
	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = Color("f5d9ed")
	wash.modulate.a = 0.0
	wash.mouse_filter = Control.MOUSE_FILTER_STOP
	transition.add_child(wash)
	var fade := create_tween()
	fade.tween_property(wash, "modulate:a", 0.88, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_add_launch_cloud(transition, Vector2(size.x * 0.04, size.y * 0.43), Vector2(size.x * 0.48, 112), Color("fff0c9"))
	_add_launch_cloud(transition, Vector2(size.x * 0.58, size.y * 0.58), Vector2(size.x * 0.50, 136), Color("d8f6f0"))
	_add_launch_cloud(transition, Vector2(size.x * 0.18, size.y * 0.72), Vector2(size.x * 0.64, 94), Color("e6dcff"))
	var lamp_count := 8
	var lamp_size := clampf(size.x * 0.13, 48.0, 76.0)
	var button_center := _play_button.get_global_rect().get_center() - get_global_rect().position
	for i in lamp_count:
		var lamp := Bulb.new()
		lamp.color = Palette.BULBS[i % Palette.BULBS.size()]
		lamp.custom_minimum_size = Vector2(lamp_size, lamp_size)
		lamp.size = Vector2(lamp_size, lamp_size)
		lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lamp.pivot_offset = lamp.size / 2.0
		lamp.scale = Vector2(0.55, 0.55)
		lamp.modulate.a = 0.0
		var start_x := size.x * (0.12 + 0.108 * i)
		var start_y := button_center.y + (float(i % 3) - 1.0) * lamp_size * 0.35
		lamp.position = Vector2(start_x - lamp_size / 2.0, start_y)
		transition.add_child(lamp)
		lamp.set_lit(true)
		var end_x := clampf(start_x + (float(i % 3) - 1.0) * size.x * 0.08, lamp_size * 0.5, size.x - lamp_size * 0.5)
		var end_y := size.y * (0.18 + 0.105 * (i % 4))
		var delay := float(i) * 0.07
		var rise := create_tween().set_parallel(true)
		rise.tween_property(lamp, "position", Vector2(end_x - lamp_size / 2.0, end_y), 0.95).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		rise.tween_property(lamp, "scale", Vector2.ONE, 0.3).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rise.tween_property(lamp, "modulate:a", 1.0, 0.18).set_delay(delay)
		rise.tween_property(lamp, "rotation", 0.12 if i % 2 == 0 else -0.12, 0.42).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var lights := create_tween()
	for b in bulbs:
		lights.tween_callback(b.set_lit.bind(true))
		lights.tween_interval(0.07)
	await get_tree().create_timer(1.65).timeout
	State.go("res://scenes/level_select.tscn")


func _add_launch_cloud(parent: Control, cloud_position: Vector2, cloud_size: Vector2, color: Color) -> void:
	var cloud := Panel.new()
	cloud.position = cloud_position
	cloud.size = cloud_size
	cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.48)
	style.set_corner_radius_all(int(cloud_size.y * 0.5))
	cloud.add_theme_stylebox_override("panel", style)
	cloud.modulate.a = 0.0
	parent.add_child(cloud)
	var tween := create_tween()
	tween.tween_property(cloud, "modulate:a", 1.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _open_settings() -> void:
	if is_instance_valid(_settings):
		return
	_settings = SettingsPanel.new()
	add_child(_settings)

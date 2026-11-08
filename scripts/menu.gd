extends Control

var bulbs: Array[Bulb] = []
var _step := 0
var _settings: SettingsPanel
var _timer: Timer
var _starting := false


func _ready() -> void:
	State.sfx.duck(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	margin.add_child(box)

	box.add_child(_spacer())

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	var gear := GearButton.new()
	gear.custom_minimum_size = Vector2(72, 72)
	gear.pressed.connect(_open_settings)
	top.add_child(gear)
	box.add_child(top)

	box.add_child(_bulb_row())
	box.add_child(_title())
	box.add_child(Ui.label("apague todas as luzes", 26, Palette.BASE))
	box.add_child(_spacer())

	var play := Ui.button("Jogar", Palette.BULBS[0], 40)
	play.custom_minimum_size = Vector2(0, 88)
	play.pressed.connect(_play)
	box.add_child(play)

	var bottom := Control.new()
	bottom.custom_minimum_size = Vector2(0, 48)
	box.add_child(bottom)


func _spacer() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


func _bulb_row() -> HBoxContainer:
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


func _play() -> void:
	if _starting:
		return
	_starting = true
	_timer.stop()
	State.sfx.start()
	var t := create_tween()
	for b in bulbs:
		t.tween_callback(b.set_lit.bind(true))
		t.tween_interval(0.08)
	t.tween_interval(0.2)
	t.tween_callback(State.go.bind("res://scenes/level_select.tscn"))

func _open_settings() -> void:
	if is_instance_valid(_settings):
		return
	_settings = SettingsPanel.new()
	add_child(_settings)
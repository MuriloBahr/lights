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


func _ready() -> void:
	State.sfx.duck(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := WorldBackdrop.new()
	backdrop.setup(1)
	add_child(backdrop)
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	_margin.add_child(box)

	box.add_child(_spacer())

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	var gear := GearButton.new()
	gear.custom_minimum_size = Vector2(72, 72)
	gear.pressed.connect(_open_settings)
	top.add_child(gear)
	box.add_child(top)

	_bulb_row = _make_bulb_row()
	box.add_child(_bulb_row)
	_title_label = _title()
	box.add_child(_title_label)
	box.add_child(Ui.label("apague todas as luzes", 26, Palette.BASE))
	box.add_child(_spacer())

	_play_button = Ui.button("Jogar", Palette.BULBS[0], 40)
	_play_button.pressed.connect(_play)
	box.add_child(_play_button)

	var bottom := Control.new()
	bottom.custom_minimum_size = Vector2(0, 48)
	box.add_child(bottom)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func _spacer() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


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
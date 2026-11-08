extends Control

var bulbs: Array[Bulb] = []
var _step := 0


func _ready() -> void:
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

	var timer := Timer.new()
	timer.wait_time = 0.35
	timer.autostart = true
	timer.timeout.connect(_tick)
	add_child(timer)
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
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")
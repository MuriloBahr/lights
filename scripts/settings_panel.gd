class_name SettingsPanel
extends Control

const ROWS = [["music", "Música"], ["sfx", "Efeitos"], ["vibration", "Vibração"]]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.OFF
	sb.set_corner_radius_all(32)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(440, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	box.add_child(Ui.label("Configurações", 36))
	for row in ROWS:
		box.add_child(_row(row[0], row[1]))
	
	var how := Ui.button("Como jogar", Palette.BULBS[3])
	how.pressed.connect(_open_how)
	box.add_child(how)

	var close := Ui.button("Fechar", Palette.BULBS[2])
	close.pressed.connect(queue_free)
	box.add_child(close)


func _row(key: String, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()

	var label := Ui.label(text, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var bulb := Bulb.new()
	bulb.custom_minimum_size = Vector2(76, 76)
	bulb.color = Palette.BULBS[1]
	bulb.ready.connect(bulb.set_lit.bind(State.settings[key]))
	bulb.pressed.connect(_toggle.bind(key, bulb))
	row.add_child(bulb)
	return row


func _toggle(key: String, bulb: Bulb) -> void:
	var on: bool = not State.settings[key]
	State.set_setting(key, on)
	bulb.set_lit(on)
	State.sfx.tap()


func _open_how() -> void:
	add_child(HowToPanel.new())
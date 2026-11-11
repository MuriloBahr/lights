class_name Ui
extends RefCounted


static func button(text: String, color: Color, font_size := 28, sound := "click") -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 64)
	b.add_theme_font_size_override("font_size", font_size)
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(key, Palette.FACE)
	b.add_theme_stylebox_override("normal", _box(color, 6))
	b.add_theme_stylebox_override("hover", _box(color.lightened(0.12), 6))
	b.add_theme_stylebox_override("pressed", _box(color.darkened(0.08), 2))
	b.add_theme_stylebox_override("disabled", _box(Palette.OFF, 6))
	b.pressed.connect(State.sfx.glow if sound == "glow" else State.sfx.click)
	return b


static func app_navigation(parent: Control, active: String) -> HBoxContainer:
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	var tabs := [
		{"title": "Fases", "id": "levels", "path": "res://scenes/level_select.tscn", "color": Palette.BULBS[3]},
		{"title": "Missões", "id": "missions", "path": "res://scenes/missions.tscn", "color": Palette.BULBS[4]},
		{"title": "Temas", "id": "themes", "path": "res://scenes/themes.tscn", "color": Palette.BULBS[2]},
	]
	for tab in tabs:
		var button_color: Color = tab["color"] if tab["id"] == active else Palette.OFF
		var button := Ui.button(String(tab["title"]), button_color, 18)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 58
		button.pressed.connect(State.go.bind(String(tab["path"])))
		nav.add_child(button)
	parent.add_child(nav)
	return nav


static func label(text: String, size: int, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func _box(color: Color, depth: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(22)
	sb.border_width_bottom = depth
	sb.border_color = color.darkened(0.3)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	return sb

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
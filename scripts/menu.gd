extends Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	box.custom_minimum_size = Vector2(240, 0)
	center.add_child(box)

	var title := Label.new()
	title.text = "Lights"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	box.add_child(_make_button("Jogar", _play))
	box.add_child(_make_button("Sair", get_tree().quit))


func _make_button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	return b


func _play() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

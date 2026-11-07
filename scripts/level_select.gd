extends Control

const COLUMNS := 5
const CELL := Vector2(90, 90)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var title := Label.new()
	title.text = "Fases"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	center.add_child(grid)

	for i in State.levels.size():
		var id := int(State.levels[i]["id"])
		var b := Button.new()
		b.custom_minimum_size = CELL
		b.text = "%d\n%s" % [id, _stars_text(State.stars_for(id))]
		b.disabled = not State.is_unlocked(id)
		b.pressed.connect(_play.bind(i))
		grid.add_child(b)

	var back := Button.new()
	back.text = "Voltar"
	back.pressed.connect(_back)
	root.add_child(back)


func _stars_text(n: int) -> String:
	return "★".repeat(n) + "☆".repeat(3 - n)


func _play(index: int) -> void:
	State.current_level = index
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

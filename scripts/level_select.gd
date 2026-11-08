extends Control

const COLUMNS := 3
const CARD := Vector2(148, 156)


func _ready() -> void:
	State.sfx.duck(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var back := Ui.button("<", Palette.BULBS[3])
	back.custom_minimum_size = Vector2(64, 64)
	back.pressed.connect(_back)
	top.add_child(back)
	var title := Ui.label("Fases", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(64, 0)
	top.add_child(balance)

	var progress := Ui.label("", 24, Palette.BASE)
	root.add_child(progress)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 12
	root.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	center.add_child(grid)

	var total := 0
	for i in State.levels.size():
		total += State.stars_for(int(State.levels[i]["id"]))
		grid.add_child(_card(i))
	progress.text = "%d / %d lâmpadas" % [total, State.levels.size() * 3]


func _card(index: int) -> Button:
	var level: Dictionary = State.levels[index]
	var id := int(level["id"])
	var unlocked := State.is_unlocked(id)
	var color: Color = Palette.BULBS[(int(level["size"]) - 3) % Palette.BULBS.size()]

	var b := Ui.button("", color)
	b.custom_minimum_size = CARD
	b.disabled = not unlocked
	b.pressed.connect(_play.bind(index))

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)

	var number := Ui.label(str(id), 44, Palette.FACE if unlocked else Palette.OFF_FACE)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(number)

	if unlocked:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(row)
		var earned := State.stars_for(id)
		for i in 3:
			var bulb := Bulb.new()
			bulb.custom_minimum_size = Vector2(40, 40)
			bulb.color = Palette.BULBS[1]
			bulb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bulb.ready.connect(bulb.set_lit.bind(i < earned))
			row.add_child(bulb)
	return b


func _play(index: int) -> void:
	State.current_level = index
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
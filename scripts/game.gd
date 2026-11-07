extends Control

const LEVELS_PATH := "res://data/levels.json"
const COLOR_ON := Color("f5c542")
const COLOR_OFF := Color("2b2f3a")
const GRID_PX := 420.0

var board := Board.new()
var levels: Array = []
var level_index := 0
var grid := GridContainer.new()
var info := Label.new()
var buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	levels = JSON.parse_string(FileAccess.get_file_as_string(LEVELS_PATH))["levels"]
	_build_ui()
	board.changed.connect(_refresh)
	board.solved.connect(_on_solved)
	_load(level_index)


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 24)
	add_child(root)

	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	center.add_child(grid)

	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 16)
	root.add_child(bar)
	bar.add_child(_make_button("Desfazer", board.undo))
	bar.add_child(_make_button("Reiniciar", board.reset))


func _make_button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	return b


func _load(index: int) -> void:
	level_index = index
	var level: Dictionary = levels[index]
	_build_grid(int(level["size"]))
	board.load_level(level)


func _build_grid(n: int) -> void:
	for b in buttons:
		b.queue_free()
	buttons.clear()
	grid.columns = n
	var px := int(GRID_PX / n)
	for y in n:
		for x in n:
			var b := Button.new()
			b.custom_minimum_size = Vector2(px, px)
			b.pressed.connect(board.toggle.bind(x, y))
			grid.add_child(b)
			buttons.append(b)


func _refresh() -> void:
	for i in buttons.size():
		buttons[i].modulate = COLOR_ON if board.cells[i] == 1 else COLOR_OFF
	var level: Dictionary = levels[level_index]
	info.text = "Fase %d  |  Toques: %d  |  Par: %d" % [level["id"], board.moves.size(), level["par"]]


func _on_solved() -> void:
	info.text += "  |  Resolvido!"
	await get_tree().create_timer(1.0).timeout
	if level_index + 1 < levels.size():
		_load(level_index + 1)

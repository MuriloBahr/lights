extends Control

const GRID_PX := 420.0

var board := Board.new()
var levels: Array = []
var level_index := 0
var grid := GridContainer.new()
var info := Ui.label("", 24, Palette.BASE)
var bulbs: Array[Bulb] = []
var hint := Ui.label("", 22, Palette.OFF_FACE)
var title := Ui.label("", 36)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	levels = State.levels
	level_index = State.current_level
	_build_ui()
	board.changed.connect(_refresh)
	board.solved.connect(_on_solved)
	_load(level_index)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var back := Ui.button("<", Palette.BULBS[3])
	back.custom_minimum_size = Vector2(64, 64)
	back.pressed.connect(_back)
	top.add_child(back)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(64, 0)
	top.add_child(balance)

	root.add_child(info)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(center)
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	center.add_child(grid)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	root.add_child(bar)
	bar.add_child(_action("Desfazer", Palette.BULBS[4], board.undo))
	bar.add_child(_action("Reiniciar", Palette.BULBS[1], board.reset))


func _action(text: String, color: Color, callback: Callable) -> Button:
	var b := Ui.button(text, color)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(callback)
	return b


func _load(index: int) -> void:
	level_index = index
	var level: Dictionary = levels[index]
	_build_grid(int(level["size"]))
	board.load_level(level)


func _build_grid(n: int) -> void:
	for b in bulbs:
		b.queue_free()
	bulbs.clear()
	grid.columns = n
	var px := int(GRID_PX / n)
	for y in n:
		for x in n:
			var b := Bulb.new()
			b.custom_minimum_size = Vector2(px, px)
			b.color = Palette.BULBS[(x + 2 * y) % Palette.BULBS.size()]
			b.pressed.connect(board.toggle.bind(x, y))
			grid.add_child(b)
			bulbs.append(b)


func _refresh() -> void:
	for i in bulbs.size():
		bulbs[i].set_lit(board.cells[i] == 1)
	var level: Dictionary = levels[level_index]
	title.text = "Fase %d" % level["id"]
	info.text = "Toques %d  /  Par %d" % [board.moves.size(), level["par"]]
	hint.text = level.get("hint", "")

func _on_solved() -> void:
	var level: Dictionary = levels[level_index]
	State.record(int(level["id"]), _stars(board.moves.size(), int(level["par"])))
	info.text += "  |  Resolvido!"
	await get_tree().create_timer(1.0).timeout
	if level_index + 1 < levels.size():
		_load(level_index + 1)
	else:
		_back()


func _stars(moves: int, par: int) -> int:
	if moves <= par:
		return 3
	return 2 if moves <= par + 2 else 1


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

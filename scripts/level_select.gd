extends Control

const MAX_CARD := Vector2(148, 156)
const CARD_GAP := 12

var _columns := 3
var _card_size := MAX_CARD
var _list: VBoxContainer
var _progress: Label
var _daily: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := WorldBackdrop.new()
	backdrop.setup(1)
	add_child(backdrop)
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
	var back := Ui.button("<", Palette.BULBS[3], 28, "glow")
	back.custom_minimum_size = Vector2(64, 64)
	back.pressed.connect(_back)
	top.add_child(back)
	var title := Ui.label("Fases", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(64, 0)
	top.add_child(balance)

	var compact := get_viewport_rect().size.x < 400.0
	_progress = Ui.label("", 20 if compact else 24, Palette.BASE)
	root.add_child(_progress)
	_daily = Ui.button("", Palette.BULBS[4], 20 if compact else 28)
	_daily.pressed.connect(_daily_pressed)
	root.add_child(_daily)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 5
	root.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(center)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", CARD_GAP)
	_list.mouse_filter = Control.MOUSE_FILTER_PASS
	center.add_child(_list)
	get_viewport().size_changed.connect(_rebuild_level_list)
	_rebuild_level_list()


func _rebuild_level_list() -> void:
	if not is_instance_valid(_list):
		return
	var available_width := get_viewport_rect().size.x - 48.0
	var compact := get_viewport_rect().size.x < 400.0
	_progress.add_theme_font_size_override("font_size", 20 if compact else 24)
	_daily.add_theme_font_size_override("font_size", 20 if compact else 28)
	_columns = clampi(int((available_width + CARD_GAP) / (120.0 + CARD_GAP)), 1, 5)
	var card_width := minf(MAX_CARD.x, (available_width - CARD_GAP * (_columns - 1)) / _columns)
	_card_size = Vector2(maxf(100.0, card_width), MAX_CARD.y)
	_list.custom_minimum_size.x = _columns * _card_size.x + (_columns - 1) * CARD_GAP
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	var total := 0
	var current := -1
	var grid: GridContainer
	for i in State.levels.size():
		var level: Dictionary = State.levels[i]
		total += State.stars_for(int(level["id"]))
		var w := int(level["world"])
		if w != current:
			current = w
			_list.add_child(_world_header(State.worlds[w - 1]))
			grid = _new_grid()
			_list.add_child(grid)
		grid.add_child(_card(i, State.worlds[w - 1]))
	_progress.text = "%d / %d lâmpadas" % [total, State.levels.size() * 3]
	if compact:
		_daily.text = "Desafio diário%s" % (" · concluído!" if State.is_daily_completed() else "")
	else:
		_daily.text = "Desafio de hoje · sem cronômetro%s" % (" · concluído!" if State.is_daily_completed() else "")


func _world_header(world: Dictionary) -> PanelContainer:
	var color: Color = Palette.BULBS[int(world["color"])]
	var compact := get_viewport_rect().size.x < 400.0
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.1)
	style.border_color = Color(color, 0.56)
	style.border_width_left = 4
	style.set_corner_radius_all(18)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(box)
	var world_name := Ui.label(str(world["name"]), 28 if compact else 34, color)
	world_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(world_name)
	var rule := Ui.label(str(world["rule"]), 17 if compact else 20, Palette.BASE)
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rule)
	return panel


func _new_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = _columns
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.add_theme_constant_override("h_separation", CARD_GAP)
	grid.add_theme_constant_override("v_separation", CARD_GAP)
	return grid


func _card(index: int, world: Dictionary) -> Button:
	var level: Dictionary = State.levels[index]
	var id := int(level["id"])
	var unlocked := State.is_unlocked(id)
	var compact := get_viewport_rect().size.x < 400.0
	var color: Color = Palette.BULBS[int(world["color"])]

	var b := Ui.button("", color)
	b.custom_minimum_size = _card_size
	b.disabled = not unlocked
	b.pressed.connect(_play.bind(index))

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)

	var number := Ui.label(str(id), 36 if compact else 44, Palette.FACE if unlocked else Palette.OFF_FACE)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(number)

	if unlocked:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(row)
		var earned := State.stars_for(id)
		var star_size := minf(40.0, (_card_size.x - 24.0) / 3.0)
		for i in 3:
			var bulb := Bulb.new()
			bulb.custom_minimum_size = Vector2(star_size, star_size)
			bulb.color = Palette.BULBS[1]
			bulb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bulb.ready.connect(bulb.set_lit.bind(i < earned))
			row.add_child(bulb)
	return b


func _play(index: int) -> void:
	State.daily_mode = false
	State.current_level = index
	State.go("res://scenes/game.tscn")


func _daily_pressed() -> void:
	State.start_daily_challenge()
	State.go("res://scenes/game.tscn")


func _back() -> void:
	State.go("res://scenes/menu.tscn")

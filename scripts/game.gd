extends Control

const GRID_PX := 420.0

var board := Board.new()
var levels: Array = []
var level_index := 0
var grid := GridContainer.new()
var _root: VBoxContainer
var _margin: MarginContainer
var _center: CenterContainer
var _toolbar: BoxContainer
var _toolbar_compact := false
var info := Ui.label("", 24, Palette.BASE)
var bulbs: Array[Bulb] = []
var hint := Ui.label("", 22, Palette.OFF_FACE)
var title := Ui.label("", 36)
var backdrop := WorldBackdrop.new()
var _win: WinPanel
var _hint_button: Button
var _hints_used := 0
var _combo_streak := 0
var _goal: Array = []
var _preview := GoalPreview.new()
var _settings_panel: SettingsPanel
var _selected_move_index := -1
var _selected_move_cells: Array[int] = []
var _selected_move_hint := ""
var _selected_move_hint_active := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	levels = State.levels
	level_index = State.daily_level if State.daily_mode else State.current_level
	State.sfx.duck(true)
	_build_ui()
	board.changed.connect(_on_board_changed)
	board.solved.connect(_on_solved)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_load(level_index)


func _build_ui() -> void:
	add_child(backdrop)
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_margin)

	_root = VBoxContainer.new()
	_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_margin.add_child(_root)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_PASS
	_root.add_child(top)
	var back := Ui.button("<", Palette.BULBS[3])
	back.custom_minimum_size = Vector2(64, 64)
	back.pressed.connect(_back)
	top.add_child(back)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(title)
	var gear := GearButton.new()
	gear.custom_minimum_size = Vector2(64, 64)
	gear.pressed.connect(_open_settings)
	top.add_child(gear)

	_root.add_child(info)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(hint)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_preview)

	_center = CenterContainer.new()
	_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_center.mouse_filter = Control.MOUSE_FILTER_PASS
	_root.add_child(_center)
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	_center.add_child(grid)

	_rebuild_toolbar()
	_apply_responsive_layout()


func _rebuild_toolbar() -> void:
	var compact := get_viewport_rect().size.x < 400.0
	if is_instance_valid(_toolbar) and compact == _toolbar_compact:
		return
	if is_instance_valid(_toolbar):
		_root.remove_child(_toolbar)
		_toolbar.queue_free()
	_toolbar_compact = compact
	if compact:
		_toolbar = VBoxContainer.new()
		_toolbar.mouse_filter = Control.MOUSE_FILTER_PASS
		_toolbar.add_theme_constant_override("separation", 8)
		var primary_actions := HBoxContainer.new()
		primary_actions.mouse_filter = Control.MOUSE_FILTER_PASS
		primary_actions.add_theme_constant_override("separation", 8)
		_hint_button = _action("Dica", Palette.BULBS[2], _show_hint)
		primary_actions.add_child(_hint_button)
		primary_actions.add_child(_action("Desfazer", Palette.BULBS[4], _undo_move))
		_toolbar.add_child(primary_actions)
		_toolbar.add_child(_action("Reiniciar", Palette.BULBS[1], _restart_level))
	else:
		_toolbar = HBoxContainer.new()
		_toolbar.mouse_filter = Control.MOUSE_FILTER_PASS
		_toolbar.add_theme_constant_override("separation", 16)
		_hint_button = _action("Dica", Palette.BULBS[2], _show_hint)
		_toolbar.add_child(_hint_button)
		_toolbar.add_child(_action("Desfazer", Palette.BULBS[4], _undo_move))
		_toolbar.add_child(_action("Reiniciar", Palette.BULBS[1], _restart_level))
	_root.add_child(_toolbar)


func _apply_responsive_layout() -> void:
	if not is_instance_valid(_margin):
		return
	_rebuild_toolbar()
	var viewport_size := get_viewport_rect().size
	var horizontal_margin := clampf(viewport_size.x * 0.045, 12.0, 24.0)
	var vertical_margin := clampf(viewport_size.y * 0.025, 10.0, 24.0)
	for side in ["left", "right"]:
		_margin.add_theme_constant_override("margin_" + side, int(horizontal_margin))
	for side in ["top", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, int(vertical_margin))
	_root.add_theme_constant_override("separation", int(clampf(viewport_size.y * 0.02, 8.0, 20.0)))
	var board_px := minf(GRID_PX, minf(viewport_size.x - horizontal_margin * 2.0, viewport_size.y * 0.48))
	var gap_px := float(maxi(0, grid.columns - 1) * 4)
	var cell_px := floorf(maxf(120.0, board_px - gap_px) / maxf(1.0, float(grid.columns)))
	for bulb in bulbs:
		bulb.custom_minimum_size = Vector2(cell_px, cell_px)
	if board.size > 0 and board.cells.size() == bulbs.size() and not levels.is_empty() and level_index < levels.size() and is_instance_valid(_hint_button):
		_refresh()


func _action(text: String, color: Color, callback: Callable) -> Button:
	var font_size := 21 if get_viewport_rect().size.x < 400.0 else 26
	var b := Ui.button(text, color, font_size)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(callback)
	return b


func _load(index: int) -> void:
	State.sfx.enter()
	level_index = index
	if not State.daily_mode:
		State.set_current_level(index)
	_hints_used = 0
	_combo_streak = 0
	var level: Dictionary = levels[index]
	_goal = level.get("goal", [])
	_preview.setup(level)
	backdrop.setup(int(level["world"]), int(level["id"]), State.visual_theme())
	_build_grid(level)
	board.load_level(_board_level(level))
	_show_world_intro_if_needed(level)


func _show_world_intro_if_needed(level: Dictionary) -> void:
	var world_id := int(level["world"])
	var first_in_world := level_index == 0 or int(levels[level_index - 1]["world"]) != world_id
	if not first_in_world:
		return
	var setting_key := "seen_howto_v2"
	if world_id != 1:
		setting_key = "seen_world_intro_v2_%d" % world_id
	if bool(State.settings.get(setting_key, false)):
		return
	State.set_setting(setting_key, true)
	var demo_level := level
	if world_id == 4:
		for candidate in levels:
			if int(candidate["world"]) == world_id and candidate.has("shape") and candidate.has("mask"):
				demo_level = candidate
				break
	var panel := HowToPanel.new()
	panel.setup(State.worlds[world_id - 1], demo_level)
	add_child(panel)


func _build_grid(level: Dictionary) -> void:
	_clear_selected_move()
	for b in bulbs:
		grid.remove_child(b)
		b.queue_free()
	bulbs.clear()
	var n := int(level["size"])
	var mask: Array = level.get("mask", [])
	grid.columns = n
	for y in n:
		for x in n:
			var b := Bulb.new()
			b.color = Palette.BULBS[(x + 2 * y) % Palette.BULBS.size()]
			if mask.is_empty() or int(mask[y * n + x]) == 1:
				b.pressed.connect(_on_bulb_pressed.bind(x, y))
			else:
				b.modulate.a = 0.0
				b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid.add_child(b)
			bulbs.append(b)
			b.appear(0.45 * (x + y) / float(2 * n - 2))
	_apply_responsive_layout()


func _refresh() -> void:
	for i in bulbs.size():
		bulbs[i].set_lit(_is_lit(i))
	var level: Dictionary = levels[level_index]
	var phase_title := String(level.get("title", "Fase %d" % int(level["id"])))
	title.text = "Desafio • %s" % phase_title if State.daily_mode else phase_title
	var compact := get_viewport_rect().size.x < 400.0
	title.add_theme_font_size_override("font_size", 28 if compact else 36)
	info.add_theme_font_size_override("font_size", 18 if compact else 24)
	hint.add_theme_font_size_override("font_size", 17 if compact else 22)
	var world: Dictionary = State.worlds[int(level["world"]) - 1]
	title.add_theme_color_override("font_color", Palette.BULBS[int(world["color"])])
	var hint_count := int(level["par"]) - 1
	var hints_left := maxi(0, hint_count - _hints_used)
	info.text = "Toques %d/%d • Dicas %d/%d • Toque para prévia" % [board.moves.size(), level["par"], hints_left, hint_count]
	_hint_button.text = "Dica (%d)" % hints_left
	_hint_button.disabled = hints_left == 0
	hint.text = level.get("hint", "")


func _on_board_changed() -> void:
	_refresh()
	for i in board.last_touched.size():
		var cell_index := board.last_touched[i]
		if cell_index < bulbs.size():
			bulbs[cell_index].play_effect(minf(float(i) * 0.025, 0.2))
	board.last_touched.clear()


func _on_bulb_pressed(x: int, y: int) -> void:
	var index := y * board.size + x
	if _selected_move_index == index:
		_clear_selected_move()
		_apply_bulb_move(x, y)
		return
	if _selected_move_index >= 0:
		_clear_selected_move()
		return
	_select_bulb_move(x, y)


func _select_bulb_move(x: int, y: int) -> void:
	_selected_move_index = y * board.size + x
	_selected_move_cells = board.affected_cells(x, y)
	_selected_move_hint = hint.text
	_selected_move_hint_active = true
	for cell_index in _selected_move_cells:
		if cell_index >= 0 and cell_index < bulbs.size():
			bulbs[cell_index].set_preview(true)
	if _is_rule_intro_level():
		for i in _selected_move_cells.size():
			var cell_index := _selected_move_cells[i]
			if cell_index >= 0 and cell_index < bulbs.size():
				bulbs[cell_index].play_effect(minf(float(i) * 0.035, 0.14))
	hint.text = "Afeta %d lâmpadas. Toque de novo nesta para confirmar; toque fora para cancelar." % _selected_move_cells.size()
	State.sfx.click()


func _clear_selected_move() -> void:
	for cell_index in _selected_move_cells:
		if cell_index >= 0 and cell_index < bulbs.size():
			bulbs[cell_index].set_preview(false)
	_selected_move_cells.clear()
	_selected_move_index = -1
	if _selected_move_hint_active and is_instance_valid(hint):
		hint.text = _selected_move_hint
	_selected_move_hint = ""
	_selected_move_hint_active = false


func _apply_bulb_move(x: int, y: int) -> void:
	var lit_before := _lit_count()
	board.toggle(x, y)
	State.sfx.toggle(board.get_cell(x, y) == 1)
	if _lit_count() < lit_before:
		_combo_streak += 1
		if _combo_streak >= 2:
			State.sfx.toggle(_is_lit(y * board.size + x))
			hint.text = "Combo x%d! Mais luzes apagando!" % _combo_streak
	else:
		_combo_streak = 0


func _is_rule_intro_level() -> bool:
	var current_world := int(levels[level_index]["world"])
	var phase_in_world := 0
	for i in level_index + 1:
		if int(levels[i]["world"]) == current_world:
			phase_in_world += 1
	return phase_in_world <= 4


func _unhandled_input(event: InputEvent) -> void:
	if _selected_move_index < 0 or _selected_move_index >= bulbs.size():
		return
	var pointer_position := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		pressed = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
		pointer_position = mouse.position
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		pressed = touch.pressed
		pointer_position = touch.position
	if pressed and not bulbs[_selected_move_index].get_global_rect().has_point(pointer_position):
		_clear_selected_move()


func _lit_count() -> int:
	var count := 0
	for cell in board.cells:
		count += int(cell)
	return count


func _show_hint() -> void:
	_clear_selected_move()
	var level: Dictionary = levels[level_index]
	if _hints_used >= int(level["par"]):
		return
	var remaining := {}
	for cell in level.get("solution", []):
		var index := int(cell)
		remaining[index] = not bool(remaining.get(index, false))
	for move in board.moves:
		var index := move.y * board.size + move.x
		remaining[index] = not bool(remaining.get(index, false))

	var choices: Array[int] = []
	for index in remaining:
		if bool(remaining[index]):
			choices.append(int(index))
	if choices.is_empty():
		return
	choices.sort()
	_hints_used += 1
	bulbs[choices[0]].pulse_hint()
	_refresh()
	hint.text = "Dica: toque na luz pulsando. Restam %d." % maxi(0, int(level["par"]) - _hints_used)


func _restart_level() -> void:
	_clear_selected_move()
	_hints_used = 0
	_combo_streak = 0
	board.reset()


func _undo_move() -> void:
	_clear_selected_move()
	board.undo()


func _on_solved() -> void:
	var level: Dictionary = levels[level_index]
	var moves := board.moves.size()
	var earned := _stars(moves, int(level["par"]))
	if State.daily_mode:
		State.record_daily_completion()
	else:
		State.record(int(level["id"]), earned)
	State.sfx.win()
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(_win):
		return
	_win = WinPanel.new()
	_win.setup(moves, int(level["par"]), earned, level_index + 1 < levels.size() and not State.daily_mode, State.daily_mode, String(level.get("easter_egg", "")))
	_win.chosen.connect(_on_win_choice)
	add_child(_win)


func _on_win_choice(action: String) -> void:
	match action:
		"next":
			_load(level_index + 1)
		"retry":
			_restart_level()
		"levels":
			State.daily_mode = false
			_back()


func _stars(moves: int, par: int) -> int:
	if moves <= par:
		return 3
	return 2 if moves <= par + 2 else 1


func _back() -> void:
	_clear_selected_move()
	State.daily_mode = false
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _open_settings() -> void:
	_clear_selected_move()
	if is_instance_valid(_settings_panel):
		return
	_settings_panel = SettingsPanel.new()
	add_child(_settings_panel)


func _is_lit(i: int) -> bool:
	var goal_bit := 0 if _goal.is_empty() else int(_goal[i])
	return (int(board.cells[i]) ^ goal_bit) == 1


func _board_level(level: Dictionary) -> Dictionary:
	if _goal.is_empty():
		return level
	var shifted := level.duplicate()
	var diff: Array = []
	for i in _goal.size():
		diff.append(int(level["grid"][i]) ^ int(_goal[i]))
	shifted["grid"] = diff
	return shifted

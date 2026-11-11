class_name HowToPanel
extends Control

var board := Board.new()
var _bulbs: Array[Bulb] = []
var _msg := Ui.label("", 26, Palette.BULBS[1])
var _world: Dictionary = {}
var _demo_level: Dictionary = {}
var _is_world_intro := false
var _demo_goal: Array = []
var _goal_preview := GoalPreview.new()
var _selected_demo_index := -1
var _selected_demo_cells: Array[int] = []


func setup(world: Dictionary, level: Dictionary) -> void:
	_is_world_intro = true
	_world = world
	_demo_level = level.duplicate(true)
	_demo_goal = _demo_level.get("goal", [])
	if _demo_goal.is_empty():
		var demo_size := int(_demo_level["size"])
		_demo_level["grid"] = []
		for i in demo_size * demo_size:
			_demo_level["grid"].append(0)


func _ready() -> void:
	var viewport_size := get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_PASS
	if _world.is_empty():
		_world = State.worlds[0]
	if _demo_level.is_empty():
		_demo_level = {"size": 3, "grid": [0, 0, 0, 0, 0, 0, 0, 0, 0]}
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_cancel_demo_on_dim)
	add_child(dim)

	var safe_margin := MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	for side in ["left", "right", "top", "bottom"]:
		safe_margin.add_theme_constant_override("margin_" + side, 12)
	add_child(safe_margin)
	var scroll := ScrollContainer.new()
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	safe_margin.add_child(scroll)
	var centered_content := CenterContainer.new()
	centered_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centered_content.mouse_filter = Control.MOUSE_FILTER_PASS
	centered_content.custom_minimum_size.y = maxf(0.0, viewport_size.y - 24.0)
	scroll.add_child(centered_content)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.OFF
	sb.set_corner_radius_all(32)
	var compact := viewport_size.x < 400.0
	sb.set_content_margin_all(int(clampf(viewport_size.x * 0.055, 14.0, 28.0)))
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(minf(460.0, viewport_size.x - 48.0), 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centered_content.add_child(panel)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_theme_constant_override("separation", 10 if compact else 14)
	panel.add_child(box)

	var world_id := int(_world["id"])
	var heading := Ui.label("Como jogar" if world_id == 1 else "Novo mundo: %s" % _world["name"], 28 if compact else 36)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(heading)
	if world_id == 1:
		box.add_child(_text("Toque numa lâmpada para ver o alcance. Ela e as vizinhas de cima, de baixo e dos lados invertem. Toque nela de novo para confirmar; toque fora para cancelar."))
	else:
		box.add_child(_text(str(_world["rule"]) + " Toque numa lâmpada para ver o alcance; toque nela de novo para confirmar."))
	box.add_child(_demo_grid())
	if not _demo_goal.is_empty():
		_goal_preview.setup(_demo_level)
		_goal_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(_goal_preview)
	_msg.add_theme_font_size_override("font_size", 20 if compact else 26)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg.text = _default_demo_text()
	_msg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_msg)
	if world_id == 1:
		box.add_child(_text("Apague todas as luzes com o mínimo de toques. Quanto menos toques, mais lâmpadas você ganha."))
		box.add_child(_text("Você tem uma dica por jogada mínima. Se resolver sem pedir ajuda, não gasta nenhuma."))

	var row: BoxContainer
	if compact:
		row = VBoxContainer.new()
	else:
		row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8 if compact else 12)
	var button_font := 20 if compact else 28
	var again := Ui.button("Rever efeito", Palette.BULBS[1], button_font)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(_reset_demo)
	row.add_child(again)
	var done := Ui.button("Começar fase" if _is_world_intro else "Fechar", Palette.BULBS[2], button_font, "glow")
	done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	done.pressed.connect(queue_free)
	row.add_child(done)
	box.add_child(row)

	board.changed.connect(_refresh)
	board.solved.connect(_on_solved)
	var board_level := _demo_level
	if not _demo_goal.is_empty():
		board_level = _demo_level.duplicate(true)
		var difference: Array = []
		for i in _demo_goal.size():
			difference.append(int(_demo_level["grid"][i]) ^ int(_demo_goal[i]))
		board_level["grid"] = difference
	board.load_level(board_level)
	_animate(panel)


func _text(text: String) -> Label:
	var l := Ui.label(text, 18 if get_viewport_rect().size.x < 400.0 else 22, Palette.BASE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _demo_grid() -> Control:
	var vp := get_viewport_rect().size
	var n := int(_demo_level["size"])
	var cell_size := clampi(int(minf((vp.x - 96.0) / n, (vp.y - 420.0) / n)), 32, 100)
	var wrap := CenterContainer.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_PASS
	var grid := GridContainer.new()
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.columns = n
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	wrap.add_child(grid)
	var mask: Array = _demo_level.get("mask", [])
	for y in n:
		for x in n:
			var b := Bulb.new()
			b.custom_minimum_size = Vector2(cell_size, cell_size)
			b.color = Palette.BULBS[(x + 2 * y) % Palette.BULBS.size()]
			if not mask.is_empty() and int(mask[y * n + x]) == 0:
				b.modulate.a = 0.0
				b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				b.pressed.connect(_tap.bind(x, y))
			grid.add_child(b)
			_bulbs.append(b)
	return wrap


func _tap(x: int, y: int) -> void:
	var index := y * board.size + x
	if _selected_demo_index == index:
		_clear_demo_selection()
		_msg.text = "Boa! Continue até formar o desenho." if not _demo_goal.is_empty() else "Viu como a regra muda as luzes? Toque em Rever efeito para testar de novo."
		board.toggle(x, y)
		State.sfx.toggle(board.get_cell(x, y) == 1)
		for i in board.last_touched.size():
			var cell_index := board.last_touched[i]
			_bulbs[cell_index].play_effect(minf(float(i) * 0.025, 0.2))
		board.last_touched.clear()
		return
	if _selected_demo_index >= 0:
		_clear_demo_selection()
		_msg.text = "Prévia cancelada. Toque numa lâmpada para tentar de novo."
		return
	_selected_demo_index = index
	_selected_demo_cells = board.affected_cells(x, y)
	for i in _selected_demo_cells.size():
		var cell_index := _selected_demo_cells[i]
		if cell_index >= 0 and cell_index < _bulbs.size():
			_bulbs[cell_index].set_preview(true)
			_bulbs[cell_index].play_effect(minf(float(i) * 0.035, 0.14))
	_msg.text = "Afeta %d lâmpadas. Toque de novo nesta para testar; toque fora para cancelar." % _selected_demo_cells.size()


func _clear_demo_selection() -> void:
	for cell_index in _selected_demo_cells:
		if cell_index >= 0 and cell_index < _bulbs.size():
			_bulbs[cell_index].set_preview(false)
	_selected_demo_cells.clear()
	_selected_demo_index = -1


func _cancel_demo_on_dim(event: InputEvent) -> void:
	if _selected_demo_index < 0:
		return
	var pressed := false
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		pressed = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if pressed:
		_clear_demo_selection()
		_msg.text = "Prévia cancelada. Toque numa lâmpada para tentar de novo."


func _unhandled_input(event: InputEvent) -> void:
	if _selected_demo_index < 0 or _selected_demo_index >= _bulbs.size():
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
	if pressed and not _bulbs[_selected_demo_index].get_global_rect().has_point(pointer_position):
		_clear_demo_selection()
		_msg.text = "Prévia cancelada. Toque numa lâmpada para tentar de novo."


func _refresh() -> void:
	for i in _bulbs.size():
		var goal_bit := 0 if _demo_goal.is_empty() else int(_demo_goal[i])
		_bulbs[i].set_lit((int(board.cells[i]) ^ goal_bit) == 1)


func _on_solved() -> void:
	_msg.text = "Boa! Agora experimente a fase de verdade."
	State.sfx.ding(1)


func _reset_demo() -> void:
	_clear_demo_selection()
	board.reset()
	for bulb in _bulbs:
		bulb.play_effect(0.0)
	_msg.text = _default_demo_text()


func _default_demo_text() -> String:
	return "Toque numa lâmpada para ver o alcance; as afetadas piscam. Toque nela de novo para formar o desenho. Isso não gasta dicas." if not _demo_goal.is_empty() else "Toque numa lâmpada para ver o alcance; as afetadas piscam. Toque nela de novo para testar. Isso não gasta dicas."


func _animate(panel: Control) -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.6, 0.6)
	panel.modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "modulate:a", 1.0, 0.2)

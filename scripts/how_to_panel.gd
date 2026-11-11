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
	if _world.is_empty():
		_world = State.worlds[0]
	if _demo_level.is_empty():
		_demo_level = {"size": 3, "grid": [0, 0, 0, 0, 0, 0, 0, 0, 0]}
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var safe_margin := MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		safe_margin.add_theme_constant_override("margin_" + side, 12)
	add_child(safe_margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	safe_margin.add_child(scroll)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.OFF
	sb.set_corner_radius_all(32)
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 400.0
	sb.set_content_margin_all(int(clampf(viewport_size.x * 0.055, 14.0, 28.0)))
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(minf(460.0, viewport_size.x - 48.0), 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10 if compact else 14)
	panel.add_child(box)

	var world_id := int(_world["id"])
	box.add_child(Ui.label("Como jogar" if world_id == 1 else "Novo mundo: %s" % _world["name"], 28 if compact else 36))
	if world_id == 1:
		box.add_child(_text("Toque numa lâmpada: ela e as vizinhas de cima, de baixo e dos lados invertem."))
	else:
		box.add_child(_text(str(_world["rule"])))
	box.add_child(_demo_grid())
	if not _demo_goal.is_empty():
		_goal_preview.setup(_demo_level)
		box.add_child(_goal_preview)
	_msg.add_theme_font_size_override("font_size", 20 if compact else 26)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg.text = "Tente deixar o tabuleiro igual ao desenho. Isso não gasta dicas." if not _demo_goal.is_empty() else "Experimente no tabuleiro: toque para ver a regra em ação. Isso não gasta dicas."
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
	return l


func _demo_grid() -> Control:
	var vp := get_viewport_rect().size
	var n := int(_demo_level["size"])
	var cell_size := clampi(int(minf((vp.x - 96.0) / n, (vp.y - 420.0) / n)), 32, 100)
	var wrap := CenterContainer.new()
	var grid := GridContainer.new()
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
			b.pressed.connect(_tap.bind(x, y))
			if not mask.is_empty() and int(mask[y * n + x]) == 0:
				b.modulate.a = 0.0
				b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid.add_child(b)
			_bulbs.append(b)
	return wrap


func _tap(x: int, y: int) -> void:
	_msg.text = "Boa! Continue até formar o desenho." if not _demo_goal.is_empty() else "Viu como a regra muda as luzes? Toque em Rever efeito para testar de novo."
	board.toggle(x, y)
	State.sfx.toggle(board.get_cell(x, y) == 1)
	for i in board.last_touched.size():
		var cell_index := board.last_touched[i]
		_bulbs[cell_index].play_effect(minf(float(i) * 0.025, 0.2))
	board.last_touched.clear()


func _refresh() -> void:
	for i in _bulbs.size():
		var goal_bit := 0 if _demo_goal.is_empty() else int(_demo_goal[i])
		_bulbs[i].set_lit((int(board.cells[i]) ^ goal_bit) == 1)


func _on_solved() -> void:
	_msg.text = "Boa! Agora experimente a fase de verdade."
	State.sfx.ding(1)


func _reset_demo() -> void:
	board.reset()
	for bulb in _bulbs:
		bulb.play_effect(0.0)
	_msg.text = "Tente deixar o tabuleiro igual ao desenho. Isso não gasta dicas." if not _demo_goal.is_empty() else "Experimente no tabuleiro: toque para ver a regra em ação. Isso não gasta dicas."


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

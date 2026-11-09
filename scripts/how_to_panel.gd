class_name HowToPanel
extends Control

const DEMO := {"id": 0, "size": 3, "grid": [0, 1, 0, 1, 1, 1, 0, 1, 0]}

var cell := clampi(int((get_viewport_rect().size.y - 512.0) / 3.0), 40, 76)
var board := Board.new()
var _bulbs: Array[Bulb] = []
var _msg := Ui.label("", 26, Palette.BULBS[1])
var _resetting := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.OFF
	sb.set_corner_radius_all(32)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(minf(460.0, get_viewport_rect().size.x - 48.0), 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	box.add_child(Ui.label("Como jogar", 40))
	box.add_child(_text("Toque numa lâmpada: ela e as vizinhas de cima, de baixo e dos lados invertem."))
	box.add_child(_demo_grid())
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_msg)
	box.add_child(_text("Apague todas as luzes com o mínimo de toques. Quanto menos toques, mais lâmpadas você ganha."))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var again := Ui.button("Recomeçar", Palette.BULBS[1])
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(board.reset)
	row.add_child(again)
	var done := Ui.button("Entendi", Palette.BULBS[2], 28, "glow")
	done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	done.pressed.connect(queue_free)
	row.add_child(done)
	box.add_child(row)

	board.changed.connect(_refresh)
	board.solved.connect(_on_solved)
	board.load_level(DEMO)
	_msg.text = "Experimente: toque na lâmpada do meio"
	_animate(panel)


func _text(text: String) -> Label:
	var l := Ui.label(text, 22, Palette.BASE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _demo_grid() -> Control:
	var wrap := CenterContainer.new()
	var grid := GridContainer.new()
	var vp := get_viewport_rect().size
	var cell := clampi(int(minf((vp.x - 112.0) / 3.0, (vp.y - 496.0) / 3.0)), 48, 110)
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	wrap.add_child(grid)
	for y in 3:
		for x in 3:
			var b := Bulb.new()
			b.custom_minimum_size = Vector2(cell, cell)
			b.color = Palette.BULBS[(x + 2 * y) % Palette.BULBS.size()]
			b.pressed.connect(_tap.bind(x, y))
			grid.add_child(b)
			_bulbs.append(b)
	return wrap


func _tap(x: int, y: int) -> void:
	if _resetting:
		return
	board.toggle(x, y)
	State.sfx.tap()


func _refresh() -> void:
	for i in _bulbs.size():
		_bulbs[i].set_lit(board.cells[i] == 1)


func _on_solved() -> void:
	_resetting = true
	_msg.text = "Isso! Todas apagadas"
	State.sfx.ding(1)
	await get_tree().create_timer(1.6).timeout
	if not is_inside_tree():
		return
	board.reset()
	_msg.text = "De novo: toque na lâmpada do meio"
	_resetting = false


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
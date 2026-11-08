class_name WinPanel
extends Control

signal chosen(action: String)

var _moves := 0
var _par := 0
var _earned := 0
var _has_next := false
var _counter := Ui.label("", 30, Palette.BASE)
var _bulbs: Array[Bulb] = []


func setup(moves: int, par: int, earned: int, has_next: bool) -> void:
	_moves = moves
	_par = par
	_earned = earned
	_has_next = has_next


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
	panel.custom_minimum_size = Vector2(440, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)

	box.add_child(Ui.label("Resolvido!", 48, Palette.BULBS[1]))
	box.add_child(Ui.label(["Boa!", "Muito bem!", "Perfeito!"][_earned - 1], 28, Palette.BASE))
	box.add_child(_bulb_row())
	box.add_child(_counter)
	_set_counter(0.0)

	if _has_next:
		box.add_child(_choice("Próxima", Palette.BULBS[2], "next"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_choice("Repetir", Palette.BULBS[1], "retry"))
	row.add_child(_choice("Fases", Palette.BULBS[3], "levels"))
	box.add_child(row)

	_animate(panel)


func _bulb_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		var b := Bulb.new()
		b.custom_minimum_size = Vector2(96, 96)
		b.color = Palette.BULBS[1]
		row.add_child(b)
		_bulbs.append(b)
	return row


func _choice(text: String, color: Color, action: String) -> Button:
	var b := Ui.button(text, color)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(_pick.bind(action))
	return b


func _pick(action: String) -> void:
	chosen.emit(action)
	queue_free()


func _set_counter(value: float) -> void:
	_counter.text = "Toques %d  /  Par %d" % [int(value), _par]


func _animate(panel: Control) -> void:
	await get_tree().process_frame
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.6, 0.6)
	panel.modulate.a = 0.0

	var t := create_tween().set_parallel(true)
	t.tween_property(panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "modulate:a", 1.0, 0.25)
	t.tween_method(_set_counter, 0.0, float(_moves), 0.6)
	_confetti()

	await get_tree().create_timer(0.5).timeout
	for i in _earned:
		if not is_inside_tree():
			return
		_bulbs[i].set_lit(true)
		State.sfx.ding(i)
		await get_tree().create_timer(0.45).timeout


func _confetti() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(size.x / 2.0, -20)
	p.amount = 40 + 20 * _earned
	p.one_shot = true
	p.explosiveness = 0.85
	p.lifetime = 2.2
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(size.x / 2.0, 6)
	p.direction = Vector2.DOWN
	p.spread = 20
	p.gravity = Vector2(0, 420)
	p.initial_velocity_min = 120
	p.initial_velocity_max = 320
	p.angular_velocity_min = -240
	p.angular_velocity_max = 240
	p.scale_amount_min = 6
	p.scale_amount_max = 12

	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in Palette.BULBS.size():
		offsets.append(float(i) / Palette.BULBS.size())
		colors.append(Palette.BULBS[i])
	g.offsets = offsets
	g.colors = colors
	p.color_initial_ramp = g

	p.emitting = true
	add_child(p)
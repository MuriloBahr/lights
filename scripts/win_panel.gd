class_name WinPanel
extends Control

signal chosen(action: String)

var _moves := 0
var _par := 0
var _earned := 0
var _has_next := false
var _daily := false
var _easter_egg := ""
var _boss_name := ""
var _new_boss_theme := -1
var _new_boss_track := -1
var _theme_unlock_card: Control
var _counter := Ui.label("", 30, Palette.BASE)
var _bulbs: Array[Bulb] = []


func setup(moves: int, par: int, earned: int, has_next: bool, daily := false, easter_egg := "", boss_name := "", new_boss_theme := -1, new_boss_track := -1) -> void:
	_moves = moves
	_par = par
	_earned = earned
	_has_next = has_next
	_daily = daily
	_easter_egg = easter_egg
	_boss_name = boss_name
	_new_boss_theme = new_boss_theme
	_new_boss_track = new_boss_track


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 400.0
	var panel_margin := int(clampf(viewport_size.x * 0.055, 14.0, 28.0))

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
	sb.set_content_margin_all(panel_margin)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(minf(440.0, viewport_size.x - 24.0), 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14 if compact else 20)
	panel.add_child(box)

	var heading := "Desafio concluído!" if _daily else ("Chefe derrotado!" if not _boss_name.is_empty() else "Resolvido!")
	box.add_child(Ui.label(heading, 30 if compact else (42 if _daily else 48), Palette.BULBS[1]))
	box.add_child(Ui.label(_boss_name if not _boss_name.is_empty() else ["Boa!", "Muito bem!", "Perfeito!"][_earned - 1], 22 if compact else 28, Palette.BASE))
	if _new_boss_theme >= 4 or _new_boss_track > 0:
		_theme_unlock_card = _make_theme_unlock_card(_new_boss_theme, _new_boss_track, compact)
		box.add_child(_theme_unlock_card)
	if not _easter_egg.is_empty():
		box.add_child(Ui.label(_easter_egg, 48 if compact else 64, Palette.BULBS[0]))
	box.add_child(_bulb_row(72.0 if compact else 96.0))
	box.add_child(_counter)
	_counter.add_theme_font_size_override("font_size", 23 if compact else 30)
	_set_counter(0.0)

	if _has_next:
		box.add_child(_choice("Próxima", Palette.BULBS[2], "next"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8 if compact else 12)
	row.add_child(_choice("Repetir", Palette.BULBS[1], "retry", 20 if compact else 28))
	row.add_child(_choice("Fases", Palette.BULBS[3], "levels", 20 if compact else 28))
	box.add_child(row)

	_animate(panel)


func _make_theme_unlock_card(theme_id: int, track_world_id: int, compact: bool) -> Control:
	var world_id := theme_id - 3 if theme_id >= 4 else track_world_id
	var accent: Color = Palette.BULBS[int(State.worlds[world_id - 1]["color"])]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 82 if compact else 98)
	panel.pivot_offset = panel.custom_minimum_size * 0.5
	panel.modulate.a = 0.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.OFF, 0.78)
	style.border_color = Color(accent, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", style)
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(0, 70 if compact else 86)
	frame.clip_contents = true
	panel.add_child(frame)
	var art := WorldBackdrop.new()
	art.setup(world_id, 20, theme_id)
	frame.add_child(art)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 8)
	row.offset_left = 8
	row.offset_top = 4
	row.offset_right = -8
	row.offset_bottom = -4
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(row)
	var avatar := BossPortrait.new()
	avatar.custom_minimum_size = Vector2(60 if compact else 72, 60 if compact else 72)
	avatar.setup(world_id, String(State.worlds[world_id - 1]["boss"]), false)
	avatar.set_process(false)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(avatar)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 1)
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var has_new_theme := theme_id >= 4
	var has_new_track := track_world_id > 0
	var title_text := "NOVOS DESBLOQUEIOS!" if has_new_theme and has_new_track else ("TEMA DESBLOQUEADO!" if has_new_theme else "TRILHA DESBLOQUEADA!")
	var title := Ui.label(title_text, 15 if compact else 17, Palette.BULBS[1])
	title.add_theme_color_override("font_outline_color", Palette.FACE)
	title.add_theme_constant_override("outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	copy.add_child(title)
	if has_new_theme:
		var theme_name := Ui.label("Tema: %s" % State.visual_theme_name(theme_id), 16 if compact else 18, Color.WHITE)
		theme_name.add_theme_color_override("font_outline_color", Palette.FACE)
		theme_name.add_theme_constant_override("outline_size", 3)
		theme_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		theme_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(theme_name)
	if has_new_track:
		var track_name := String(State.worlds[track_world_id - 1]["boss"])
		var track_label := Ui.label("♫ Trilha: %s" % track_name, 15 if compact else 17, Color.WHITE)
		track_label.add_theme_color_override("font_outline_color", Palette.FACE)
		track_label.add_theme_constant_override("outline_size", 3)
		track_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		copy.add_child(track_label)
	return panel


func _bulb_row(bulb_size: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in 3:
		var b := Bulb.new()
		b.custom_minimum_size = Vector2(bulb_size, bulb_size)
		b.color = Palette.BULBS[1]
		row.add_child(b)
		_bulbs.append(b)
	return row


func _choice(text: String, color: Color, action: String, font_size := 28) -> Button:
	var b := Ui.button(text, color, font_size)
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
	if is_instance_valid(_theme_unlock_card):
		await get_tree().create_timer(0.2).timeout
		var reveal := create_tween().set_parallel(true)
		_theme_unlock_card.scale = Vector2(0.72, 0.72)
		reveal.tween_property(_theme_unlock_card, "scale", Vector2.ONE, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		reveal.tween_property(_theme_unlock_card, "modulate:a", 1.0, 0.32)

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

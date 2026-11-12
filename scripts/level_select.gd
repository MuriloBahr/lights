extends Control

const CARD_GAP := 12

class WorldPath extends Control:
	var entries: Array[Dictionary] = []
	var accent := Color.WHITE
	var focused_card: Control
	var node_size := Vector2(82, 82)
	var node_step := 104.0
	var amplitude := 0.22

	func setup(level_entries: Array[Dictionary], color: Color, compact: bool) -> void:
		entries = level_entries.duplicate()
		accent = color
		node_size = Vector2(76, 76) if compact else Vector2(88, 88)
		node_step = 96.0 if compact else 112.0
		custom_minimum_size = Vector2(0, entries.size() * node_step + 20.0)
		mouse_filter = Control.MOUSE_FILTER_PASS
		for entry in entries:
			var index := int(entry["index"])
			var level: Dictionary = State.levels[index]
			var unlocked := State.is_unlocked(int(level["id"]))
			var boss := bool(entry["boss"])
			var color_for_node: Color = Palette.BULBS[1] if boss else accent
			var button := Ui.button("", color_for_node, 24, "glow")
			button.custom_minimum_size = node_size + (Vector2(12, 12) if boss else Vector2.ZERO)
			button.size = button.custom_minimum_size
			button.disabled = not unlocked
			button.focus_mode = Control.FOCUS_NONE
			var on_pressed: Callable = entry["on_pressed"]
			button.pressed.connect(on_pressed.bind(index))
			add_child(button)
			var content := VBoxContainer.new()
			content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			content.alignment = BoxContainer.ALIGNMENT_CENTER
			content.add_theme_constant_override("separation", 0)
			content.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(content)
			if boss:
				var boss_label := Ui.label("CHEFE", 12, Palette.FACE if unlocked else Palette.OFF_FACE)
				boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				boss_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
				content.add_child(boss_label)
			var number := Ui.label(str(int(level["id"])), 28 if compact else 32, Palette.FACE if unlocked else Palette.OFF_FACE)
			number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			number.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(number)
			if unlocked:
				var marks := LevelLampMarks.new()
				marks.earned = State.stars_for(int(level["id"]))
				marks.custom_minimum_size = Vector2(node_size.x - 18.0, 18.0)
				marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
				marks.queue_redraw()
				content.add_child(marks)
			if int(entry["index"]) == int(entry["focus_index"]):
				focused_card = button
		call_deferred("_position_nodes")

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_position_nodes()

	func _position_nodes() -> void:
		if entries.is_empty() or size.x <= 0.0:
			return
		for i in entries.size():
			var button := get_child(i) as Control
			var lane: float = [0.0, -1.0, 0.0, 1.0][i % 4]
			var center_x := size.x * (0.5 + lane * amplitude)
			var center_y := 24.0 + node_step * (float(i) + 0.5)
			button.position = Vector2(center_x - button.size.x * 0.5, center_y - button.size.y * 0.5)
		queue_redraw()

	func _draw() -> void:
		if entries.size() < 2 or size.x <= 0.0:
			return
		for i in entries.size() - 1:
			var a := _node_center(i)
			var b := _node_center(i + 1)
			draw_line(a, b, Color(accent, 0.28), 8.0, true)
			draw_line(a, b, Color(Palette.OFF, 0.55), 3.0, true)

	func _node_center(index: int) -> Vector2:
		var lane: float = [0.0, -1.0, 0.0, 1.0][index % 4]
		return Vector2(size.x * (0.5 + lane * amplitude), 24.0 + node_step * (float(index) + 0.5))

class LevelLampMarks extends Control:
	var earned := 0

	func _draw() -> void:
		var lamp_size := minf(size.y, size.x / 3.2)
		var radius := lamp_size * 0.34
		for i in 3:
			var x := size.x * (float(i) + 0.5) / 3.0
			var center := Vector2(x, size.y * 0.38)
			var is_lit := i < earned
			var glow := 1.0 if is_lit else 0.0
			var body := Palette.OFF.lerp(Palette.BULBS[1], glow)
			if is_lit:
				for ring in 3:
					draw_arc(center, radius * (1.2 + 0.14 * ring), 0.0, TAU, 28, Color(Palette.BULBS[1], 0.12 - ring * 0.025), 1.4, true)
			var neck_top := center.y + radius * 0.8
			var neck_bottom := center.y + lamp_size * 0.32
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - radius * 0.55, neck_top), Vector2(x + radius * 0.55, neck_top),
				Vector2(x + radius * 0.4, neck_bottom), Vector2(x - radius * 0.4, neck_bottom),
			]), body)
			var base_rect := Rect2(x - radius * 0.5, neck_bottom, radius, lamp_size * 0.12)
			draw_rect(base_rect, Palette.BASE, true)
			draw_circle(Vector2(base_rect.position.x, base_rect.position.y + base_rect.size.y * 0.5), base_rect.size.y * 0.5, Palette.BASE)
			draw_circle(Vector2(base_rect.end.x, base_rect.position.y + base_rect.size.y * 0.5), base_rect.size.y * 0.5, Palette.BASE)
			draw_circle(center, radius, body)
			draw_circle(center + Vector2(-radius * 0.4, -radius * 0.4), radius * 0.16, Color(1, 1, 1, 0.25 + 0.3 * glow))
			_draw_face(center, radius, is_lit)

	func _draw_face(center: Vector2, radius: float, is_lit: bool) -> void:
		var eye_y := center.y + radius * 0.05
		var eye_x := radius * 0.38
		var line_width := maxf(1.0, radius * 0.09)
		var face_color := Color(Palette.FACE, 1.0) if is_lit else Palette.OFF_FACE
		if is_lit:
			draw_circle(Vector2(center.x - eye_x, eye_y), radius * 0.1, face_color)
			draw_circle(Vector2(center.x + eye_x, eye_y), radius * 0.1, face_color)
			draw_arc(Vector2(center.x, eye_y + radius * 0.1), radius * 0.2, 0.2, PI - 0.2, 12, face_color, line_width, true)
			draw_circle(center + Vector2(-radius * 0.64, radius * 0.24), radius * 0.12, Color(Palette.BLUSH, 0.6))
			draw_circle(center + Vector2(radius * 0.64, radius * 0.24), radius * 0.12, Color(Palette.BLUSH, 0.6))
		else:
			draw_line(Vector2(center.x - eye_x - radius * 0.1, eye_y), Vector2(center.x - eye_x + radius * 0.1, eye_y), face_color, line_width, true)
			draw_line(Vector2(center.x + eye_x - radius * 0.1, eye_y), Vector2(center.x + eye_x + radius * 0.1, eye_y), face_color, line_width, true)
			draw_circle(center + Vector2(0, radius * 0.28), radius * 0.05, face_color)


var _list: VBoxContainer
var _progress: Label
var _test_unlock_button: Button
var _return_button: Button
var _scroll: ScrollContainer
var _current_card: Control
var _touch_id := -1
var _touch_start := Vector2.ZERO
var _touch_start_scroll := 0
var _touch_scrolling := false
var _focus_index := 0
var _returning_to_current := false
var _settings_panel: SettingsPanel


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := WorldBackdrop.new()
	backdrop.setup(1, 0, State.visual_theme())
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
	var gear := GearButton.new()
	gear.custom_minimum_size = Vector2(64, 64)
	gear.pressed.connect(_open_settings)
	top.add_child(gear)

	var compact := get_viewport_rect().size.x < 400.0
	_progress = Ui.label("", 20 if compact else 24, Palette.BASE)
	root.add_child(_progress)
	# _test_unlock_button = Ui.button("Liberar todas as fases (teste)", Palette.BULBS[5], 17)
	# _test_unlock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# _test_unlock_button.custom_minimum_size.y = 48
	# _test_unlock_button.pressed.connect(_toggle_test_unlock)
	# root.add_child(_test_unlock_button)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.scroll_deadzone = 5
	root.add_child(_scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", CARD_GAP)
	_list.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.add_child(_list)
	_scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)
	_return_button = Ui.button("Voltar à fase atual", Palette.BULBS[1], 18)
	_return_button.pressed.connect(_return_to_current)
	_return_button.visible = false
	root.add_child(_return_button)
	Ui.app_navigation(root, "levels")
	get_viewport().size_changed.connect(_rebuild_level_list)
	_rebuild_level_list()


func _input(event: InputEvent) -> void:
	if not is_instance_valid(_scroll):
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _scroll.get_global_rect().has_point(touch.position):
				_touch_id = touch.index
				_touch_start = touch.position
				_touch_start_scroll = _scroll.scroll_vertical
				_touch_scrolling = false
		elif touch.index == _touch_id:
			if _touch_scrolling:
				get_viewport().set_input_as_handled()
			_touch_id = -1
			_touch_scrolling = false
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_id:
			var delta_y := drag.position.y - _touch_start.y
			if not _touch_scrolling and absf(delta_y) >= 8.0:
				_touch_scrolling = true
			if _touch_scrolling:
				_scroll.scroll_vertical = _touch_start_scroll - roundi(delta_y)
				get_viewport().set_input_as_handled()


func _rebuild_level_list() -> void:
	if not is_instance_valid(_list):
		return
	var compact := get_viewport_rect().size.x < 400.0
	_progress.add_theme_font_size_override("font_size", 20 if compact else 24)
	_list.custom_minimum_size.x = 0
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	var total := 0
	var current := -1
	var world_entries: Array[Dictionary] = []
	var current_world_id := -1
	_current_card = null
	if State.requested_level_index >= 0:
		_focus_index = clampi(State.requested_level_index, 0, State.levels.size() - 1)
		State.requested_level_index = -1
	else:
		_focus_index = _level_to_focus()
	for i in State.levels.size():
		var level: Dictionary = State.levels[i]
		total += State.stars_for(int(level["id"]))
		var w := int(level["world"])
		if current_world_id != -1 and w != current_world_id:
			_add_world_path(current, world_entries, compact)
			world_entries.clear()
		if w != current_world_id:
			current = w
			current_world_id = w
		world_entries.append({"index": i, "boss": i == State.levels.size() - 1 or int(State.levels[i + 1]["world"]) != w, "focus_index": _focus_index, "on_pressed": Callable(self, "_play")})
	if not world_entries.is_empty():
		_add_world_path(current, world_entries, compact)
	_progress.text = "Lâmpadas das fases: %d / %d" % [total, State.levels.size() * 3]
	# _test_unlock_button.text = "Desativar liberação de teste" if State.temporary_unlock_all else "Liberar todas as fases (teste)"
	call_deferred("_scroll_to_current")


func _toggle_test_unlock() -> void:
	State.temporary_unlock_all = not State.temporary_unlock_all
	_rebuild_level_list()


func _add_world_path(world_id: int, entries: Array[Dictionary], compact: bool) -> void:
	_list.add_child(_world_header(State.worlds[world_id - 1]))
	var path := WorldPath.new()
	path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path.setup(entries, Palette.BULBS[int(State.worlds[world_id - 1]["color"])], compact)
	_list.add_child(path)
	if is_instance_valid(path.focused_card):
		_current_card = path.focused_card


func _level_to_focus() -> int:
	if State.temporary_unlock_all and State.has_current_level:
		return clampi(State.current_level, 0, State.levels.size() - 1)
	for i in State.levels.size():
		var id := int(State.levels[i]["id"])
		if State.is_unlocked(id):
			if State.stars_for(id) == 0:
				return i
	if State.has_current_level:
		return clampi(State.current_level, 0, State.levels.size() - 1)
	return 0


func _scroll_to_current(animated := false) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(_current_card) or not is_instance_valid(_scroll):
		return
	var card_y := _current_card.global_position.y - _scroll.global_position.y + float(_scroll.scroll_vertical)
	var centered_y := card_y - maxf(0.0, (_scroll.size.y - _current_card.size.y) * 0.5)
	var bar := _scroll.get_v_scroll_bar()
	var max_scroll := maxf(0.0, bar.max_value - bar.page)
	var destination := clampf(centered_y, 0.0, max_scroll)
	if animated:
		var tween := create_tween()
		tween.tween_property(_scroll, "scroll_vertical", roundi(destination), 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await tween.finished
	else:
		_scroll.scroll_vertical = roundi(destination)
	_update_return_button()


func _on_scroll_changed(_value: float) -> void:
	_update_return_button()


func _update_return_button() -> void:
	if _returning_to_current or not is_instance_valid(_return_button) or not is_instance_valid(_current_card) or not is_instance_valid(_scroll):
		return
	var view_top := _scroll.global_position.y
	var view_bottom := view_top + _scroll.size.y
	var card_top := _current_card.global_position.y
	var card_bottom := card_top + _current_card.size.y
	var fully_visible := card_top >= view_top and card_bottom <= view_bottom
	_return_button.visible = not fully_visible


func _return_to_current() -> void:
	_returning_to_current = true
	_return_button.hide()
	await _scroll_to_current(true)
	_returning_to_current = false
	_update_return_button()


func _world_header(world: Dictionary) -> PanelContainer:
	var color: Color = Palette.BULBS[int(world["color"])]
	var title_color := color.lightened(0.28)
	var panel_tint := Palette.FACE.lerp(color.darkened(0.62), 0.22)
	var compact := get_viewport_rect().size.x < 400.0
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = Color(panel_tint, 0.96)
	style.border_color = Color(title_color, 0.92)
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
	var world_name := Ui.label(str(world["name"]), 28 if compact else 34, title_color)
	world_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(world_name)
	var rule := Ui.label(str(world["rule"]), 17 if compact else 20, Color("f0ecff"))
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rule)
	if world.has("boss"):
		var boss := Ui.label("Boss: %s" % str(world["boss"]), 15 if compact else 17, Palette.BULBS[1])
		boss.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(boss)
	return panel


func _play(index: int) -> void:
	State.daily_mode = false
	State.set_current_level(index)
	State.go("res://scenes/game.tscn")


func _back() -> void:
	State.go("res://scenes/menu.tscn")


func _open_settings() -> void:
	if is_instance_valid(_settings_panel):
		return
	_settings_panel = SettingsPanel.new()
	add_child(_settings_panel)

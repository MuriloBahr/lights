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
var _boss_banner: PanelContainer
var _boss_portrait: BossPortrait
var _boss_name_label: Label
var _boss_dialogue: Label
var _boss_entrance_tween: Tween
var _boss_cutscene: Control
var _boss_intro_active := false
var _boss_moves_since_ability := 0
var _boss_ability_every := 3
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
var _selected_move_hint_color := Color.WHITE
var _selected_move_hint_active := false
var _pulsing_bulb_index := -1

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
	var compact := get_viewport_rect().size.x < 400.0
	back.custom_minimum_size = Vector2(56, 56) if compact else Vector2(64, 64)
	back.pressed.connect(_back)
	top.add_child(back)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)
	var gear := GearButton.new()
	gear.custom_minimum_size = Vector2(56, 56) if compact else Vector2(64, 64)
	gear.pressed.connect(_open_settings)
	top.add_child(gear)
	_build_boss_banner()

	_root.add_child(info)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_color_override("font_outline_color", Palette.FACE)
	hint.add_theme_constant_override("outline_size", 2)
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
	call_deferred("_fit_grid_after_layout")


func _fit_grid_after_layout() -> void:
	await get_tree().process_frame
	if is_inside_tree():
		_apply_responsive_layout()


func _build_boss_banner() -> void:
	_boss_banner = PanelContainer.new()
	_boss_banner.visible = false
	_boss_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(Palette.OFF, 0.82)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.set_corner_radius_all(24)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	_boss_banner.add_theme_stylebox_override("panel", panel_style)
	_root.add_child(_boss_banner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_banner.add_child(row)
	_boss_portrait = BossPortrait.new()
	_boss_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_boss_portrait)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 3)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	_boss_name_label = Ui.label("", 25, Palette.BULBS[1])
	_boss_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_boss_name_label)
	_boss_dialogue = Ui.label("", 16, Palette.BASE)
	_boss_dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boss_dialogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_boss_dialogue)


func _sync_boss_portrait(level: Dictionary) -> void:
	if is_instance_valid(_boss_entrance_tween) and _boss_entrance_tween.is_running():
		_boss_entrance_tween.kill()
	if is_instance_valid(_boss_cutscene):
		_boss_cutscene.queue_free()
	_boss_intro_active = false
	var boss_name := String(level.get("boss", "")) if not State.daily_mode else ""
	if boss_name.is_empty():
		_boss_banner.hide()
		_boss_portrait.set_process(false)
		_boss_banner.modulate = Color.WHITE
		_boss_banner.scale = Vector2.ONE
		_boss_name_label.modulate = Color.WHITE
		_boss_name_label.scale = Vector2.ONE
		_boss_name_label.rotation = 0.0
		_boss_dialogue.modulate = Color.WHITE
		call_deferred("_apply_responsive_layout")
		return
	_boss_banner.show()
	var compact := get_viewport_rect().size.x < 400.0
	var accent: Color = Palette.BULBS[int(State.worlds[int(level["world"]) - 1]["color"])]
	_boss_portrait.custom_minimum_size = Vector2(132, 132) if compact else Vector2(160, 160)
	_boss_portrait.setup(int(level["world"]), boss_name, false)
	_boss_name_label.text = boss_name
	_boss_name_label.add_theme_color_override("font_color", Palette.BLUSH)
	_boss_dialogue.add_theme_color_override("font_color", Palette.BULBS[2])
	_boss_name_label.add_theme_font_size_override("font_size", 24 if compact else 32)
	_boss_dialogue.text = _boss_speech(int(level["world"]), "intro")
	var style := _boss_banner.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = Color(accent, 0.8)
	style.bg_color = Color(accent, 0.14)
	_boss_banner.add_theme_stylebox_override("panel", style)
	_boss_banner.modulate = Color(1, 1, 1, 0)
	_boss_banner.scale = Vector2.ONE
	_boss_name_label.modulate = Color(1, 1, 1, 0)
	_boss_name_label.scale = Vector2.ONE
	_boss_name_label.rotation = 0.0
	_boss_dialogue.modulate = Color(1, 1, 1, 0)
	_boss_intro_active = true
	call_deferred("_play_boss_entrance", int(level["world"]), boss_name, accent)
	call_deferred("_apply_responsive_layout")


func _play_boss_entrance(world_id: int, boss_name: String, accent: Color) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree() or not is_instance_valid(_boss_banner) or not _boss_banner.visible:
		return
	var viewport_size := get_viewport_rect().size
	var target_rect := _boss_portrait.get_global_rect()
	State.sfx.boss_theme(world_id)
	var cutscene := Control.new()
	cutscene.set_anchors_preset(Control.PRESET_FULL_RECT)
	cutscene.mouse_filter = Control.MOUSE_FILTER_STOP
	cutscene.z_index = 100
	add_child(cutscene)
	_boss_cutscene = cutscene
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(Palette.OFF, 0.0)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutscene.add_child(veil)

	var name_font_size := clampi(roundi(viewport_size.x * 0.09), 28, 58)
	var name_label := Ui.label(boss_name, name_font_size, accent.lightened(0.12))
	name_label.add_theme_color_override("font_outline_color", Palette.FACE)
	name_label.add_theme_constant_override("outline_size", 5)
	name_label.position = Vector2(12, viewport_size.y * 0.25)
	name_label.size = Vector2(viewport_size.x - 24.0, 70)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.modulate.a = 0.0
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutscene.add_child(name_label)

	var portrait := BossPortrait.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2.ZERO
	portrait.position = Vector2((viewport_size.x - minf(viewport_size.x * 0.72, viewport_size.y * 0.38)) * 0.5, viewport_size.y * 0.39)
	var portrait_size := minf(viewport_size.x * 0.72, viewport_size.y * 0.38)
	portrait.size = Vector2(portrait_size, portrait_size)
	cutscene.add_child(portrait)
	portrait.setup(world_id, boss_name)
	portrait.scale = Vector2(0.78, 0.78)
	portrait.pivot_offset = portrait.size * 0.5

	_boss_entrance_tween = create_tween()
	_boss_entrance_tween.set_parallel(true)
	_boss_entrance_tween.tween_property(veil, "color:a", 0.94, 0.6)
	_boss_entrance_tween.tween_property(portrait, "scale", Vector2.ONE, 0.82).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_boss_entrance_tween.tween_property(name_label, "modulate:a", 1.0, 0.65).set_delay(0.18)
	_boss_entrance_tween.set_parallel(false)
	_boss_entrance_tween.tween_interval(1.4)
	_boss_entrance_tween.set_parallel(true)
	_boss_entrance_tween.tween_property(portrait, "position", target_rect.position, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_boss_entrance_tween.tween_property(portrait, "size", target_rect.size, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_boss_entrance_tween.tween_property(name_label, "modulate:a", 0.0, 0.3)
	_boss_entrance_tween.set_parallel(false)
	_boss_entrance_tween.tween_interval(0.01)
	_boss_entrance_tween.set_parallel(true)
	_boss_entrance_tween.tween_property(veil, "color:a", 0.0, 0.55)
	_boss_entrance_tween.tween_property(_boss_banner, "modulate:a", 1.0, 0.55)
	_boss_entrance_tween.set_parallel(false)
	_boss_entrance_tween.tween_callback(_finish_boss_entrance.bind(cutscene))


func _finish_boss_entrance(cutscene: Control) -> void:
	if is_instance_valid(_boss_banner):
		_boss_banner.modulate = Color.WHITE
		_boss_name_label.modulate = Color.WHITE
		_boss_dialogue.modulate = Color.WHITE
	_boss_intro_active = false
	if is_instance_valid(cutscene):
		cutscene.queue_free()
	if is_instance_valid(_boss_cutscene) and _boss_cutscene == cutscene:
		_boss_cutscene = null
	_trigger_boss_ability()


func _trigger_boss_ability() -> void:
	if State.daily_mode or not _boss_banner.visible or not is_instance_valid(_boss_portrait):
		return
	_boss_portrait.perform_power()
	_animate_boss_speech(int(levels[level_index]["world"]), "ability")


func _boss_speech(world_id: int, mood: String) -> String:
	var lines := {
		1: ["Zzz... a escuridão é tão quentinha.", "Hein? Você mexeu na minha luz!", "Que brilho gostoso... vou tirar uma soneca.", "Bocejo sonolento! Zzz..."],
		2: ["Minha estrela nunca erra o caminho!", "Uhu! As diagonais estão brilhando!", "Vou guardar uma estrelinha para você.", "Olhar estelar! Encontrei você!"],
		3: ["Esta nuvem fofinha protege as luzes!", "Puf! Você achou uma brecha!", "A nuvem se abriu para deixar a luz passar.", "Sopro de nuvem! Puf!"],
		4: ["Aposto que você não me encontra!", "Mudei de cor? Quase!", "Tudo bem, vou revelar minhas cores.", "Camuflagem colorida!"],
		5: ["Somos dois guardiões lunares!", "Você surpreendeu os dois!", "Agora vamos brilhar juntinhos.", "Reflexo lunar! Olha nós dois!"],
		6: ["Bzzzt! Desafio elétrico ligado!", "Faísca! Essa foi boa!", "Circuito feliz, luzes acesas!", "Tempestade elétrica! Bzzzt!"],
		7: ["Meu quadro precisa de mais cor!", "Opa, essa pintura está ficando linda!", "Pronto! Essa obra merece uma moldura.", "Pincel mágico! Splash de cor!"],
		8: ["Uma onda de luz vem aí!", "A maré virou para o seu lado!", "Que aurora bonita... você venceu.", "Maré brilhante! Splash!"],
		9: ["Sou veloz como um meteoro!", "Uau! Você acompanhou meu rastro!", "Vou cruzar o céu levando essa luz.", "Rastro meteórico! Vuuush!"],
		10: ["A escuridão também pode ser bonita.", "Seu desenho está iluminando meu reino!", "Você trouxe luz ao meu reino. Obrigada!", "Eclipse real! Contemple meu poder!"]
	}
	var character_lines: Array = lines.get(world_id, lines[1])
	var line_index := 0 if mood == "intro" else (2 if mood == "defeat" else (3 if mood == "ability" else 1))
	return String(character_lines[line_index])


func _animate_boss_speech(world_id: int, mood: String) -> void:
	_boss_dialogue.text = _boss_speech(world_id, mood)
	_boss_dialogue.pivot_offset = _boss_dialogue.size * 0.5
	_boss_dialogue.scale = Vector2(0.92, 0.92)
	var speech_tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	speech_tween.tween_property(_boss_dialogue, "scale", Vector2.ONE, 0.22)


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
	var available_height := viewport_size.y * 0.48
	if is_instance_valid(_center) and _center.size.y > 0.0:
		available_height = minf(available_height, maxf(0.0, _center.size.y - 8.0))
	var board_px := minf(GRID_PX, minf(viewport_size.x - horizontal_margin * 2.0, available_height))
	var gap_px := float(maxi(0, grid.columns - 1) * 4)
	var cell_px := maxf(1.0, floorf(maxf(0.0, board_px - gap_px) / maxf(1.0, float(grid.columns))))
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
	_boss_moves_since_ability = 0
	_boss_ability_every = 2 + posmod(int(level.get("world", 1)), 3)
	_sync_boss_portrait(level)
	if State.daily_mode or not level.has("boss"):
		State.sfx.stop_boss_theme()
	_goal = level.get("goal", [])
	_preview.setup(level)
	backdrop.setup(int(level["world"]), int(level["id"]), State.visual_theme())
	_build_grid(level)
	board.load_level(_board_level(level))
	if not _show_world_intro_if_needed(level):
		_pulse_guided_move()


func _show_world_intro_if_needed(level: Dictionary) -> bool:
	var world_id := int(level["world"])
	var first_in_world := level_index == 0 or int(levels[level_index - 1]["world"]) != world_id
	if not first_in_world:
		return false
	var setting_key := "seen_howto_v2"
	if world_id != 1:
		setting_key = "seen_world_intro_v2_%d" % world_id
	if bool(State.settings.get(setting_key, false)):
		return false
	State.set_setting(setting_key, true)
	var demo_level := level
	if world_id == 4:
		for candidate in levels:
			if int(candidate["world"]) == world_id and candidate.has("shape") and candidate.has("mask"):
				demo_level = candidate
				break
	var panel := HowToPanel.new()
	panel.setup(State.worlds[world_id - 1], demo_level)
	panel.tree_exited.connect(_pulse_guided_move)
	add_child(panel)
	return true


func _build_grid(level: Dictionary) -> void:
	_clear_selected_move()
	_stop_guided_pulse()
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
	call_deferred("_fit_grid_after_layout")


func _refresh() -> void:
	for i in bulbs.size():
		bulbs[i].set_lit(_is_lit(i))
	var level: Dictionary = levels[level_index]
	var phase_title := String(level.get("title", "Fase %d" % int(level["id"])))
	var boss_name := String(level.get("boss", "")) if not State.daily_mode else ""
	title.text = "Desafio • %s" % phase_title if State.daily_mode else ("DUELO" if not boss_name.is_empty() else phase_title)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	var compact := get_viewport_rect().size.x < 400.0
	var title_size := (15 if compact else 20) if not boss_name.is_empty() else (28 if compact else 36)
	title.add_theme_font_size_override("font_size", title_size)
	info.add_theme_font_size_override("font_size", 18 if compact else 24)
	hint.add_theme_font_size_override("font_size", 17 if compact else 22)
	var world: Dictionary = State.worlds[int(level["world"]) - 1]
	title.add_theme_color_override("font_color", Palette.BULBS[int(world["color"])])
	info.add_theme_color_override("font_color", Palette.BLUSH if not boss_name.is_empty() else Palette.BASE)
	hint.add_theme_color_override("font_color", Palette.BULBS[1] if not boss_name.is_empty() else Palette.BULBS[2])
	var hint_count := int(level["par"]) - 1
	var hints_left := maxi(0, hint_count - _hints_used)
	var move_status := "Toques %d/%d • Dicas %d/%d" % [board.moves.size(), level["par"], hints_left, hint_count]
	info.text = ("CHEFE  •  " + move_status) if not boss_name.is_empty() else (move_status + " • Toque para prévia" if level_index == 0 and not State.daily_mode else move_status)
	_hint_button.text = "Dica (%d)" % hints_left
	_hint_button.disabled = hints_left == 0
	if not boss_name.is_empty():
		hint.text = "Complete o desenho para derrotar %s!" % boss_name if not _goal.is_empty() else "Apague todas as luzes para derrotar %s!" % boss_name
	else:
		hint.text = level.get("hint", "")


func _on_board_changed() -> void:
	_refresh()
	for i in board.last_touched.size():
		var cell_index := board.last_touched[i]
		if cell_index < bulbs.size():
			bulbs[cell_index].play_effect(minf(float(i) * 0.025, 0.2))
	board.last_touched.clear()


func _on_bulb_pressed(x: int, y: int) -> void:
	if _boss_intro_active:
		return
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
	_selected_move_hint_color = hint.get_theme_color("font_color")
	_selected_move_hint_active = true
	for cell_index in _selected_move_cells:
		if cell_index >= 0 and cell_index < bulbs.size():
			bulbs[cell_index].set_preview(true)
	if level_index == 0 and not State.daily_mode:
		_set_hint_message("Afeta %d lâmpadas. Toque de novo nesta para confirmar; toque fora para cancelar." % _selected_move_cells.size(), Palette.BULBS[1])
	State.sfx.click()


func _clear_selected_move() -> void:
	for cell_index in _selected_move_cells:
		if cell_index >= 0 and cell_index < bulbs.size():
			bulbs[cell_index].set_preview(false)
	_selected_move_cells.clear()
	_selected_move_index = -1
	if _selected_move_hint_active and is_instance_valid(hint):
		hint.text = _selected_move_hint
		hint.add_theme_color_override("font_color", _selected_move_hint_color)
	_selected_move_hint = ""
	_selected_move_hint_color = Color.WHITE
	_selected_move_hint_active = false


func _set_hint_message(message: String, color: Color) -> void:
	hint.text = message
	hint.add_theme_color_override("font_color", color)


func _apply_bulb_move(x: int, y: int) -> void:
	_stop_guided_pulse()
	var lit_before := _lit_count()
	board.toggle(x, y)
	if is_instance_valid(_boss_portrait) and _boss_banner.visible and not board.is_solved():
		_boss_portrait.react_to_move()
		_animate_boss_speech(int(levels[level_index]["world"]), "react")
	State.sfx.toggle(board.get_cell(x, y) == 1)
	if _lit_count() < lit_before:
		_combo_streak += 1
		if _combo_streak >= 2:
			State.sfx.toggle(_is_lit(y * board.size + x))
			_set_hint_message("Combo x%d! Mais luzes apagando!" % _combo_streak, Palette.BLUSH)
	else:
		_combo_streak = 0
	if not board.is_solved():
		if is_instance_valid(_boss_portrait) and _boss_banner.visible:
			_boss_moves_since_ability += 1
			if _boss_moves_since_ability >= _boss_ability_every:
				_boss_moves_since_ability = 0
				_trigger_boss_ability()
		_pulse_guided_move()


func _is_rule_intro_level() -> bool:
	if State.daily_mode:
		return false
	var current_world := int(levels[level_index]["world"])
	var phase_in_world := 0
	for i in level_index + 1:
		if int(levels[i]["world"]) == current_world:
			phase_in_world += 1
	return phase_in_world <= 4


func _pulse_guided_move() -> void:
	if not _is_rule_intro_level():
		_stop_guided_pulse()
		return
	var choices := _remaining_solution_cells()
	if choices.is_empty():
		_stop_guided_pulse()
		return
	_pulse_target_bulb(choices[0], true)


func _pulse_target_bulb(index: int, repeating: bool) -> void:
	_stop_guided_pulse()
	if index < 0 or index >= bulbs.size():
		return
	_pulsing_bulb_index = index
	bulbs[index].pulse_hint(repeating)


func _stop_guided_pulse() -> void:
	if _pulsing_bulb_index >= 0 and _pulsing_bulb_index < bulbs.size():
		bulbs[_pulsing_bulb_index].stop_hint_pulse()
	_pulsing_bulb_index = -1


func _remaining_solution_cells() -> Array[int]:
	var level: Dictionary = levels[level_index]
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
	choices.sort()
	return choices


func _unhandled_input(event: InputEvent) -> void:
	if _boss_intro_active:
		return
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
	if _boss_intro_active:
		return
	_clear_selected_move()
	var level: Dictionary = levels[level_index]
	if _hints_used >= int(level["par"]):
		return
	var choices := _remaining_solution_cells()
	if choices.is_empty():
		return
	_hints_used += 1
	_pulse_target_bulb(choices[0], false)
	_refresh()
	_set_hint_message("Dica: toque na luz pulsando. Restam %d." % maxi(0, int(level["par"]) - _hints_used), Palette.BULBS[1])


func _restart_level() -> void:
	if _boss_intro_active:
		return
	_boss_moves_since_ability = 0
	_clear_selected_move()
	_stop_guided_pulse()
	_hints_used = 0
	_combo_streak = 0
	if is_instance_valid(_boss_portrait) and _boss_banner.visible:
		_boss_portrait.reset_encounter()
		_animate_boss_speech(int(levels[level_index]["world"]), "intro")
	board.reset()
	_pulse_guided_move()


func _undo_move() -> void:
	if _boss_intro_active:
		return
	_clear_selected_move()
	_stop_guided_pulse()
	board.undo()
	_pulse_guided_move()


func _on_solved() -> void:
	var level: Dictionary = levels[level_index]
	var is_boss := not State.daily_mode and level.has("boss")
	var moves := board.moves.size()
	var earned := _stars(moves, int(level["par"]))
	if State.daily_mode:
		State.record_daily_completion()
	else:
		State.record(int(level["id"]), earned)
	if is_boss and is_instance_valid(_boss_portrait) and _boss_banner.visible:
		_boss_portrait.celebrate_defeat()
		_animate_boss_speech(int(level["world"]), "defeat")
	if is_boss:
		State.sfx.boss_defeat()
	else:
		State.sfx.win()
	await get_tree().create_timer(1.05 if is_boss else 0.6).timeout
	if is_instance_valid(_win):
		return
	_win = WinPanel.new()
	_win.setup(moves, int(level["par"]), earned, level_index + 1 < levels.size() and not State.daily_mode, State.daily_mode, String(level.get("easter_egg", "")), String(level.get("boss", "")) if is_boss else "")
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
	State.sfx.stop_boss_theme()
	_clear_selected_move()
	State.daily_mode = false
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _open_settings() -> void:
	_clear_selected_move()
	if is_instance_valid(_settings_panel):
		return
	_stop_guided_pulse()
	_settings_panel = SettingsPanel.new()
	_settings_panel.tree_exited.connect(_pulse_guided_move)
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

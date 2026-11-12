extends Control

const THEME_NAMES := [
	"Noite lilás", "Algodão doce", "Jardim menta", "Céu estrelado",
	"Soninho estrelado", "Observatório da Coruja", "Reino de Nuvem", "Jardim Camaleão",
	"Dueto Lunar", "Fundo do Mar Elétrico", "Ateliê do Pintor", "Maré da Baleia Aurora",
	"Trilha do Guardião Meteoro", "Reino da Rainha",
]
const THEME_DESCRIPTIONS := [
	"Um cantinho calmo para brincar à noite.",
	"Rosa macio e cores de algodão doce.",
	"Um jardim fresquinho cheio de paz.",
	"Um céu azul para acender as estrelas.",
	"Lua sonolenta, estrelinhas e sonhos lilás.",
	"Um céu noturno cheio de constelações e brilhos dourados.",
	"Nuvens fofinhas passeiam por um céu azul clarinho.",
	"Folhas e pintinhas coloridas num jardim camuflado.",
	"Dois reflexos de lua giram juntinhos no céu violeta.",
	"Um oceano turquesa iluminado por faíscas elétricas.",
	"Um ateliê cor-de-rosa com respingos de tinta e estrelas.",
	"Ondas tranquilas, bolhas e auroras sobre o mar.",
	"Rastros brilhantes cruzam um céu roxo de meteoros.",
	"Um eclipse real com raios de luz e uma coroa cintilante.",
]
const THEME_COLORS := [
	Color("b99aff"), Color("ff9dcc"), Color("80e3c1"), Color("8fcaff"),
	Color("c5a2ff"), Color("ffe18f"), Color("b9e8ff"), Color("c4e989"),
	Color("e0aaff"), Color("65def0"), Color("ff91b7"), Color("8ce7e2"),
	Color("b8a5ff"), Color("ff82cd"),
]
const THEME_THRESHOLDS := [0, 20, 60, 120]

var _backdrop: WorldBackdrop
var _lamp_total: Label
var _next_theme: Label
var _theme_list: VBoxContainer
var _music_list: VBoxContainer
var _funds_page: VBoxContainer
var _music_page: VBoxContainer
var _funds_tab: Button
var _music_tab: Button
var _scroll: ScrollContainer
var _previewing_track := -1
var _settings_panel: SettingsPanel


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop = WorldBackdrop.new()
	_backdrop.setup(1, 0, State.visual_theme())
	add_child(_backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var back := Ui.button("<", Palette.BULBS[3], 28, "glow")
	back.custom_minimum_size = Vector2(64, 64)
	back.pressed.connect(_back)
	header.add_child(back)
	var title := Ui.label("Temas", 34)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var gear := GearButton.new()
	gear.custom_minimum_size = Vector2(64, 64)
	gear.pressed.connect(_open_settings)
	header.add_child(gear)

	var section_tabs := HBoxContainer.new()
	section_tabs.add_theme_constant_override("separation", 8)
	_funds_tab = Ui.button("Fundos", Palette.BULBS[4], 17)
	_funds_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_funds_tab.pressed.connect(_show_section.bind("fundos"))
	section_tabs.add_child(_funds_tab)
	_music_tab = Ui.button("Trilhas sonoras", Palette.OFF, 17)
	_music_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_music_tab.pressed.connect(_show_section.bind("musicas"))
	section_tabs.add_child(_music_tab)
	root.add_child(section_tabs)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.scroll_deadzone = 5
	root.add_child(_scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	_scroll.add_child(content)
	_funds_page = VBoxContainer.new()
	_funds_page.add_theme_constant_override("separation", 10)
	content.add_child(_funds_page)
	_lamp_total = Ui.label("", 21, Palette.BULBS[1])
	_lamp_total.add_theme_color_override("font_outline_color", Palette.FACE)
	_lamp_total.add_theme_constant_override("outline_size", 3)
	_funds_page.add_child(_lamp_total)
	var intro := Ui.label("Escolha um clima ou vença um chefe para ganhar o tema do seu mundo.", 17, Color("f0ecff"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_outline_color", Palette.FACE)
	intro.add_theme_constant_override("outline_size", 3)
	_funds_page.add_child(intro)
	_next_theme = Ui.label("", 17, Color("f0ecff"))
	_next_theme.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next_theme.add_theme_color_override("font_outline_color", Palette.FACE)
	_next_theme.add_theme_constant_override("outline_size", 3)
	_funds_page.add_child(_next_theme)
	_theme_list = VBoxContainer.new()
	_theme_list.add_theme_constant_override("separation", 10)
	_funds_page.add_child(_theme_list)
	_music_page = VBoxContainer.new()
	_music_page.add_theme_constant_override("separation", 10)
	content.add_child(_music_page)
	var music_heading := Ui.label("Trilhas sonoras", 26, Palette.BULBS[3])
	_music_page.add_child(music_heading)
	var music_intro := Ui.label("Derrote os chefes para colecionar e escolher suas músicas.", 16, Color("f0ecff"))
	music_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	music_intro.add_theme_color_override("font_outline_color", Palette.FACE)
	music_intro.add_theme_constant_override("outline_size", 3)
	_music_page.add_child(music_intro)
	_music_list = VBoxContainer.new()
	_music_list.add_theme_constant_override("separation", 10)
	_music_page.add_child(_music_list)
	_show_section("fundos")
	tree_exiting.connect(Callable(State.sfx, "stop_boss_theme"))
	Ui.app_navigation(root, "themes")
	_refresh()


func _show_section(section: String) -> void:
	_funds_page.visible = section == "fundos"
	_music_page.visible = section == "musicas"
	if section != "musicas" and _previewing_track > 0:
		_previewing_track = -1
		State.sfx.stop_boss_theme()
		_refresh_music_list()
	_style_section_tab(_funds_tab, Palette.BULBS[4] if section == "fundos" else Palette.OFF)
	_style_section_tab(_music_tab, Palette.BULBS[3] if section == "musicas" else Palette.OFF)
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = 0


func _style_section_tab(button: Button, color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_color = color.darkened(0.28)
	normal.border_width_bottom = 5
	normal.set_corner_radius_all(18)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.08)
	pressed.border_width_bottom = 2
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)


func _refresh() -> void:
	var total := State.total_lamps()
	_lamp_total.text = "Lâmpadas guardadas: %d" % total
	var next_threshold := -1
	for threshold in THEME_THRESHOLDS:
		if threshold > total:
			next_threshold = threshold
			break
	if next_threshold < 0:
		_next_theme.text = "Temas de lâmpadas completos • derrote chefes para ganhar temas exclusivos."
	else:
		_next_theme.text = "%d / %d lâmpadas para o próximo tema • temas especiais vêm dos chefes." % [total, next_threshold]

	for child in _theme_list.get_children():
		_theme_list.remove_child(child)
		child.queue_free()
	for theme_id in THEME_NAMES.size():
		_theme_list.add_child(_theme_card(theme_id))
	_refresh_music_list()


func _refresh_music_list() -> void:
	for child in _music_list.get_children():
		_music_list.remove_child(child)
		child.queue_free()
	_music_list.add_child(_music_card(0))
	for world_id in 3:
		_music_list.add_child(_music_card(world_id + 1))


func _theme_card(theme_id: int) -> PanelContainer:
	var unlocked := State.visual_theme_unlocked(theme_id)
	var selected := State.visual_theme() == theme_id
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	var panel_tint := Palette.FACE.lerp(THEME_COLORS[theme_id].darkened(0.62), 0.22)
	style.bg_color = Color(panel_tint, 0.97)
	style.border_color = Color(THEME_COLORS[theme_id].lightened(0.18), 0.94)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(0, 74)
	preview.clip_contents = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(preview)
	var preview_world := theme_id - 3 if theme_id >= 4 else 1
	var preview_backdrop := WorldBackdrop.new()
	preview_backdrop.setup(preview_world, 20, theme_id)
	preview.add_child(preview_backdrop)
	if theme_id >= 4:
		var avatar_center := CenterContainer.new()
		avatar_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		avatar_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.add_child(avatar_center)
		var avatar := BossPortrait.new()
		avatar.custom_minimum_size = Vector2(58, 58)
		avatar.setup(preview_world, String(State.worlds[preview_world - 1]["boss"]), false)
		avatar.set_process(false)
		avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_center.add_child(avatar)
	var heading := Ui.label(String(THEME_NAMES[theme_id]), 22, THEME_COLORS[theme_id].lightened(0.2))
	heading.add_theme_color_override("font_outline_color", Palette.FACE)
	heading.add_theme_constant_override("outline_size", 2)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(heading)
	var description := Ui.label(String(THEME_DESCRIPTIONS[theme_id]), 16, Color("f0ecff"))
	description.add_theme_color_override("font_outline_color", Palette.FACE)
	description.add_theme_constant_override("outline_size", 2)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var button_text: String
	if selected:
		button_text = "Em uso"
	elif unlocked:
		button_text = "Usar tema"
	elif theme_id >= 4:
		var boss_world_id := theme_id - 3
		var world_name := String(State.worlds[boss_world_id - 1].get("name", "mundo"))
		button_text = "Derrote o chefe • %s 20/20" % world_name
	else:
		button_text = "Desbloqueia com %d lâmpadas" % THEME_THRESHOLDS[theme_id]
	var button_font_size := 14 if theme_id >= 4 and not unlocked else 17
	var button_color: Color = THEME_COLORS[theme_id] if unlocked or theme_id >= 4 else Palette.OFF
	var button := Ui.button(button_text, button_color, button_font_size)
	button.disabled = (not unlocked and theme_id < 4) or selected
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if theme_id >= 4 and not unlocked:
		button.pressed.connect(_go_to_boss_level.bind(theme_id - 3))
	else:
		button.pressed.connect(_select_theme.bind(theme_id))
	box.add_child(button)
	return panel


func _music_card(world_id: int) -> PanelContainer:
	var unlocked := world_id == 0 or State.boss_music_unlocked(world_id)
	var selected := State.selected_music_track() == world_id
	var accent: Color = Palette.BULBS[3] if world_id == 0 else Palette.BULBS[int(State.worlds[world_id - 1]["color"])]
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FACE.lerp(accent.darkened(0.62), 0.22), 0.97)
	style.border_color = Color(accent.lightened(0.18), 0.94)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var track_name := "Tema principal" if world_id == 0 else String(State.worlds[world_id - 1]["boss"])
	var heading := Ui.label("♫  " + track_name, 21, accent.lightened(0.2))
	heading.add_theme_color_override("font_outline_color", Palette.FACE)
	heading.add_theme_constant_override("outline_size", 2)
	box.add_child(heading)
	var description_text := "A trilha original do jogo." if world_id == 0 else "Trilha especial liberada ao derrotar este chefe."
	var description := Ui.label(description_text, 15, Color("f0ecff"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_outline_color", Palette.FACE)
	description.add_theme_constant_override("outline_size", 2)
	box.add_child(description)
	if not unlocked:
		var requirement := Ui.button("Derrote o chefe • %s 20/20" % String(State.worlds[world_id - 1]["name"]), accent, 14)
		requirement.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		requirement.pressed.connect(_go_to_boss_level.bind(world_id))
		box.add_child(requirement)
		return panel
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	if world_id > 0:
		var preview_text := "Parar prévia" if _previewing_track == world_id else "Ouvir prévia"
		var preview := Ui.button(preview_text, Palette.BULBS[1], 15)
		preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preview.pressed.connect(_toggle_track_preview.bind(world_id))
		actions.add_child(preview)
	var select_text := "Em uso" if selected else "Usar trilha"
	var select := Ui.button(select_text, accent, 15)
	select.disabled = selected
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.pressed.connect(_select_music_track.bind(world_id))
	actions.add_child(select)
	return panel


func _toggle_track_preview(world_id: int) -> void:
	if _previewing_track == world_id:
		_previewing_track = -1
		State.sfx.stop_boss_theme()
	else:
		_previewing_track = world_id
		State.sfx.boss_theme(world_id)
	_refresh_music_list()


func _select_music_track(world_id: int) -> void:
	State.select_music_track(world_id)
	_previewing_track = -1
	_refresh_music_list()


func _go_to_boss_level(world_id: int) -> void:
	for index in State.levels.size():
		var level: Dictionary = State.levels[index]
		if int(level["world"]) == world_id and level.has("boss"):
			State.requested_level_index = index
			State.daily_mode = false
			State.go("res://scenes/level_select.tscn")
			return


func _select_theme(theme_id: int) -> void:
	State.select_visual_theme(theme_id)
	_backdrop.setup(1, 0, State.visual_theme())
	_refresh()


func _back() -> void:
	State.go("res://scenes/level_select.tscn")


func _open_settings() -> void:
	if is_instance_valid(_settings_panel):
		return
	_settings_panel = SettingsPanel.new()
	add_child(_settings_panel)

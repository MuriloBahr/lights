extends Control

var _backdrop: WorldBackdrop
var _level_mission_status: Label
var _daily_mission_status: Label
var _daily_button: Button
var _lamp_total: Label
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
	var title := Ui.label("Missões", 34)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var gear := GearButton.new()
	gear.custom_minimum_size = Vector2(64, 64)
	gear.pressed.connect(_open_settings)
	header.add_child(gear)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 5
	root.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	_lamp_total = Ui.label("", 22, Palette.BULBS[1])
	content.add_child(_lamp_total)
	content.add_child(_daily_card())
	content.add_child(_level_mission_card())
	Ui.app_navigation(root, "missions")
	_refresh()


func _section_label(text: String) -> Label:
	var label := Ui.label(text, 27, Palette.BULBS[4])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label


func _daily_card() -> PanelContainer:
	var panel := _panel_shell(Palette.BULBS[4])
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(_section_label("Missão de hoje"))
	var description := Ui.label("Resolva o tabuleiro diário. Sem cronômetro e com tentativas livres.", 18, Palette.BASE)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	_daily_mission_status = Ui.label("", 18, Palette.BULBS[1])
	_daily_mission_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(_daily_mission_status)
	_daily_button = Ui.button("Jogar desafio", Palette.BULBS[4], 22)
	_daily_button.pressed.connect(_play_daily)
	box.add_child(_daily_button)
	return panel


func _level_mission_card() -> PanelContainer:
	var panel := _panel_shell(Palette.BULBS[2])
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var heading := Ui.label("Uma fase por dia", 23, Palette.BULBS[2])
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(heading)
	var description := Ui.label("Conclua qualquer fase normal. Dicas e desfazer continuam valendo.", 17, Palette.BASE)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	_level_mission_status = Ui.label("", 18, Palette.BULBS[1])
	_level_mission_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(_level_mission_status)
	return panel


func _panel_shell(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.OFF, 0.92)
	style.border_color = Color(color, 0.68)
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _refresh() -> void:
	var mission_state := State.missions_for_today()
	var level_done := bool(mission_state["level"])
	var daily_done := bool(mission_state["daily"])
	_lamp_total.text = "Lâmpadas guardadas: %d" % State.total_lamps()
	_level_mission_status.text = "Concluída · +1 lâmpada" if level_done else "Recompensa: +1 lâmpada"
	_daily_mission_status.text = "Concluída · +2 lâmpadas" if daily_done else "Recompensa: +2 lâmpadas"
	_daily_button.text = "Jogar de novo" if daily_done else "Jogar desafio"


func _play_daily() -> void:
	State.start_daily_challenge()
	State.go("res://scenes/game.tscn")


func _back() -> void:
	State.daily_mode = false
	State.go("res://scenes/level_select.tscn")


func _open_settings() -> void:
	if is_instance_valid(_settings_panel):
		return
	_settings_panel = SettingsPanel.new()
	add_child(_settings_panel)

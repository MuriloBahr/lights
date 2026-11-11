extends Control

const THEME_NAMES := ["Noite lilás", "Algodão doce", "Jardim menta", "Céu estrelado"]
const THEME_DESCRIPTIONS := [
	"Um cantinho calmo para brincar à noite.",
	"Rosa macio e cores de algodão doce.",
	"Um jardim fresquinho cheio de paz.",
	"Um céu azul para acender as estrelas.",
]
const THEME_COLORS := [Color("b99aff"), Color("ff9dcc"), Color("80e3c1"), Color("8fcaff")]
const THEME_THRESHOLDS := [0, 20, 60, 120]

var _backdrop: WorldBackdrop
var _lamp_total: Label
var _next_theme: Label
var _theme_list: VBoxContainer
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

	_lamp_total = Ui.label("", 21, Palette.BULBS[1])
	root.add_child(_lamp_total)
	var intro := Ui.label("Junte lâmpadas nas fases e missões para escolher um novo clima.", 17, Palette.BASE)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 5
	root.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	_next_theme = Ui.label("", 17, Palette.BASE)
	_next_theme.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_next_theme)
	_theme_list = VBoxContainer.new()
	_theme_list.add_theme_constant_override("separation", 10)
	content.add_child(_theme_list)
	Ui.app_navigation(root, "themes")
	_refresh()


func _refresh() -> void:
	var total := State.total_lamps()
	_lamp_total.text = "Lâmpadas guardadas: %d" % total
	var next_threshold := -1
	for threshold in THEME_THRESHOLDS:
		if threshold > total:
			next_threshold = threshold
			break
	if next_threshold < 0:
		_next_theme.text = "Todos os temas estão desbloqueados!"
	else:
		_next_theme.text = "%d / %d para desbloquear o próximo tema" % [total, next_threshold]

	for child in _theme_list.get_children():
		_theme_list.remove_child(child)
		child.queue_free()
	for theme_id in THEME_NAMES.size():
		_theme_list.add_child(_theme_card(theme_id))


func _theme_card(theme_id: int) -> PanelContainer:
	var unlocked := State.visual_theme_unlocked(theme_id)
	var selected := State.visual_theme() == theme_id
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(THEME_COLORS[theme_id], 0.17)
	style.border_color = Color(THEME_COLORS[theme_id], 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var heading := Ui.label(String(THEME_NAMES[theme_id]), 22, THEME_COLORS[theme_id])
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(heading)
	var description := Ui.label(String(THEME_DESCRIPTIONS[theme_id]), 16, Palette.BASE)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	var button_text: String
	if selected:
		button_text = "Em uso"
	elif unlocked:
		button_text = "Usar tema"
	else:
		button_text = "Desbloqueia com %d lâmpadas" % THEME_THRESHOLDS[theme_id]
	var button := Ui.button(button_text, THEME_COLORS[theme_id] if unlocked else Palette.OFF, 17)
	button.disabled = not unlocked or selected
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_select_theme.bind(theme_id))
	box.add_child(button)
	return panel


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

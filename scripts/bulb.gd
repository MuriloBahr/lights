class_name Bulb
extends Control

signal pressed

var color: Color = Palette.BULBS[0]
var lit := false
var previewed := false
var _pointer_down := false
var glow := 0.0:
	set(value):
		glow = value
		queue_redraw()

var _fade: Tween
var _pop: Tween
var _hint_tween: Tween
var _effect_tween: Tween
var pulse_strength := 0.0:
	set(value):
		pulse_strength = value
		queue_redraw()
var _base_box := StyleBoxFlat.new()
var _disc_box := StyleBoxFlat.new()


func set_lit(value: bool) -> void:
	if value == lit:
		return
	lit = value
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "glow", 1.0 if lit else 0.0, 0.28).set_trans(Tween.TRANS_SINE)


func set_preview(value: bool) -> void:
	if previewed == value:
		return
	previewed = value
	queue_redraw()


func appear(delay: float) -> void:
	scale = Vector2.ZERO
	if _pop:
		_pop.kill()
	_pop = create_tween()
	_pop.tween_interval(delay)
	_pop.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func pulse_hint() -> void:
	if _hint_tween:
		_hint_tween.kill()
	scale = Vector2.ONE
	modulate = Color.WHITE
	_hint_tween = create_tween()
	_hint_tween.set_loops(3)
	_hint_tween.tween_property(self, "scale", Vector2(1.16, 1.16), 0.22).set_trans(Tween.TRANS_SINE)
	_hint_tween.parallel().tween_property(self, "modulate", Color(1.0, 0.86, 0.35), 0.22)
	_hint_tween.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE)
	_hint_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.22)


func play_effect(delay: float) -> void:
	if _effect_tween:
		_effect_tween.kill()
	_effect_tween = create_tween()
	if delay > 0.0:
		_effect_tween.tween_interval(delay)
	_effect_tween.tween_property(self, "scale", Vector2(1.14, 1.14), 0.11).set_trans(Tween.TRANS_BACK)
	_effect_tween.parallel().tween_property(self, "pulse_strength", 1.0, 0.1)
	_effect_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE)
	_effect_tween.parallel().tween_property(self, "pulse_strength", 0.0, 0.24)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size / 2.0


func _gui_input(event: InputEvent) -> void:
	var e := event as InputEventMouseButton
	if not e or e.button_index != MOUSE_BUTTON_LEFT:
		return
	if e.pressed:
		_pointer_down = true
		_bounce()
	elif _pointer_down:
		_pointer_down = false
		pressed.emit()


func _bounce() -> void:
	if _pop:
		_pop.kill()
	scale = Vector2.ONE
	_pop = create_tween()
	_pop.tween_property(self, "scale", Vector2(0.85, 0.85), 0.07)
	_pop.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _disc(center: Vector2, radius: float, col: Color) -> void:
	_disc_box.bg_color = col
	_disc_box.set_corner_radius_all(ceili(radius))
	_disc_box.anti_aliasing = true
	draw_style_box(_disc_box, Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0))


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := Vector2(size.x / 2.0, s * 0.42)
	var r := s * 0.34
	var body := Palette.OFF.lerp(color, glow)

	if previewed:
		draw_arc(c, r * 1.28, 0.0, TAU, 40, Color(Palette.BULBS[1], 0.95), maxf(3.0, s * 0.035), true)
	if pulse_strength > 0.01:
		draw_arc(c, r * 1.24, 0.0, TAU, 36, Color(color, pulse_strength * 0.8), maxf(2.0, s * 0.035), true)
	for i in 6:
		_disc(c, r * (1.1 + 0.1 * i), Color(color, 0.07 * glow))

	var neck_top := c.y + r * 0.8
	var neck_bottom := s * 0.74
	draw_colored_polygon(PackedVector2Array([
		Vector2(c.x - r * 0.55, neck_top),
		Vector2(c.x + r * 0.55, neck_top),
		Vector2(c.x + r * 0.4, neck_bottom),
		Vector2(c.x - r * 0.4, neck_bottom),
	]), body)

	_base_box.bg_color = Palette.BASE
	_base_box.set_corner_radius_all(int(s * 0.05))
	draw_style_box(_base_box, Rect2(c.x - r * 0.5, neck_bottom, r, s * 0.13))

	_disc(c, r, body)
	_disc(c + Vector2(-r * 0.4, -r * 0.4), r * 0.16, Color(1, 1, 1, 0.25 + 0.35 * glow))
	_draw_face(c, r)


func _draw_face(c: Vector2, r: float) -> void:
	var eye_y := c.y + r * 0.05
	var dx := r * 0.38
	var w := maxf(2.0, r * 0.09)

	var on_face := Color(Palette.FACE, glow)
	_disc(Vector2(c.x - dx, eye_y), r * 0.1, on_face)
	_disc(Vector2(c.x + dx, eye_y), r * 0.1, on_face)
	draw_arc(Vector2(c.x, eye_y + r * 0.1), r * 0.2, 0.2, PI - 0.2, 12, on_face, w, true)
	_disc(Vector2(c.x - r * 0.64, eye_y + r * 0.24), r * 0.12, Color(Palette.BLUSH, 0.6 * glow))
	_disc(Vector2(c.x + r * 0.64, eye_y + r * 0.24), r * 0.12, Color(Palette.BLUSH, 0.6 * glow))

	var off_face := Color(Palette.OFF_FACE, 1.0 - glow)
	draw_line(Vector2(c.x - dx - r * 0.1, eye_y), Vector2(c.x - dx + r * 0.1, eye_y), off_face, w, true)
	draw_line(Vector2(c.x + dx - r * 0.1, eye_y), Vector2(c.x + dx + r * 0.1, eye_y), off_face, w, true)
	_disc(Vector2(c.x, eye_y + r * 0.28), r * 0.05, off_face)

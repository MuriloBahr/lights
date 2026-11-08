class_name Bulb
extends Control

signal pressed

var color: Color = Palette.BULBS[0]
var lit := false
var glow := 0.0:
	set(value):
		glow = value
		queue_redraw()

var _fade: Tween
var _pop: Tween
var _base_box := StyleBoxFlat.new()


func set_lit(value: bool) -> void:
	if value == lit:
		return
	lit = value
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "glow", 1.0 if lit else 0.0, 0.28).set_trans(Tween.TRANS_SINE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size / 2.0


func _gui_input(event: InputEvent) -> void:
	var e := event as InputEventMouseButton
	if e and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_bounce()
		pressed.emit()


func _bounce() -> void:
	if _pop:
		_pop.kill()
	scale = Vector2.ONE
	_pop = create_tween()
	_pop.tween_property(self, "scale", Vector2(0.85, 0.85), 0.07)
	_pop.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := Vector2(size.x / 2.0, s * 0.42)
	var r := s * 0.34
	var body := Palette.OFF.lerp(color, glow)

	for i in 3:
		draw_circle(c, r * (1.15 + 0.22 * i), Color(color, 0.14 * glow))

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

	draw_circle(c, r, body)
	draw_circle(c + Vector2(-r * 0.4, -r * 0.4), r * 0.16, Color(1, 1, 1, 0.25 + 0.35 * glow))
	_draw_face(c, r)


func _draw_face(c: Vector2, r: float) -> void:
	var eye_y := c.y + r * 0.05
	var dx := r * 0.38
	var w := maxf(2.0, r * 0.09)

	var on_face := Color(Palette.FACE, glow)
	draw_circle(Vector2(c.x - dx, eye_y), r * 0.1, on_face)
	draw_circle(Vector2(c.x + dx, eye_y), r * 0.1, on_face)
	draw_arc(Vector2(c.x, eye_y + r * 0.1), r * 0.2, 0.2, PI - 0.2, 12, on_face, w, true)
	draw_circle(Vector2(c.x - r * 0.64, eye_y + r * 0.24), r * 0.12, Color(Palette.BLUSH, 0.6 * glow))
	draw_circle(Vector2(c.x + r * 0.64, eye_y + r * 0.24), r * 0.12, Color(Palette.BLUSH, 0.6 * glow))

	var off_face := Color(Palette.OFF_FACE, 1.0 - glow)
	draw_line(Vector2(c.x - dx - r * 0.1, eye_y), Vector2(c.x - dx + r * 0.1, eye_y), off_face, w, true)
	draw_line(Vector2(c.x + dx - r * 0.1, eye_y), Vector2(c.x + dx + r * 0.1, eye_y), off_face, w, true)
	draw_circle(Vector2(c.x, eye_y + r * 0.28), r * 0.05, off_face)
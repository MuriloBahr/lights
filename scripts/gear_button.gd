class_name GearButton
extends Control

signal pressed

var _spin: Tween
var _disc_box := StyleBoxFlat.new()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size / 2.0


func _gui_input(event: InputEvent) -> void:
	var e := event as InputEventMouseButton
	if e and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_bounce()
		pressed.emit()


func _bounce() -> void:
	if _spin:
		_spin.kill()
	_spin = create_tween().set_parallel(true)
	_spin.tween_property(self, "rotation", rotation + PI / 4.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_spin.tween_property(self, "scale", Vector2.ONE, 0.3).from(Vector2(0.85, 0.85))


func _disc(center: Vector2, radius: float, col: Color) -> void:
	_disc_box.bg_color = col
	_disc_box.set_corner_radius_all(ceili(radius))
	_disc_box.anti_aliasing = true
	draw_style_box(_disc_box, Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0))


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) * 0.44
	var col: Color = Palette.BULBS[4]
	for i in 8:
		var dir := Vector2.from_angle(TAU * i / 8.0)
		draw_line(c + dir * r * 0.7, c + dir * r, col, r * 0.34, true)
	_disc(c, r * 0.78, col)
	_disc(c, r * 0.34, Palette.BG)
class_name GoalPreview
extends Control

var _goal: Array = []
var _mask: Array = []
var _n := 0
var _frame := StyleBoxFlat.new()
var _disc_box := StyleBoxFlat.new()


func setup(level: Dictionary) -> void:
	_goal = level.get("goal", [])
	_mask = level.get("mask", [])
	_n = int(level["size"])
	visible = not _goal.is_empty()
	custom_minimum_size = Vector2(0, 96 if visible else 0)
	queue_redraw()


func _disc(center: Vector2, radius: float, col: Color) -> void:
	_disc_box.bg_color = col
	_disc_box.set_corner_radius_all(ceili(radius))
	_disc_box.anti_aliasing = true
	draw_style_box(_disc_box, Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0))


func _draw() -> void:
	if _goal.is_empty():
		return
	var cell := floorf(80.0 / _n)
	var total := cell * _n
	var origin := (size - Vector2(total, total)) / 2.0

	_frame.bg_color = Color(Palette.OFF, 0.35)
	_frame.set_corner_radius_all(20)
	draw_style_box(_frame, Rect2(origin - Vector2(18, 8), Vector2(total + 36, total + 16)))

	for y in _n:
		for x in _n:
			var i := y * _n + x
			if not _mask.is_empty() and int(_mask[i]) == 0:
				continue
			var center := origin + Vector2(x + 0.5, y + 0.5) * cell
			if int(_goal[i]) == 1:
				_disc(center, cell * 0.4, Palette.BULBS[(x + 2 * y) % Palette.BULBS.size()])
			else:
				_disc(center, cell * 0.22, Palette.OFF)
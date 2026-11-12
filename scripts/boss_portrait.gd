class_name BossPortrait
extends Control

var world_id := 1
var boss_name := ""
var _reacting := false
var _defeated := false
var _time := 0.0
var _enter_anim := 1.0
var _hit_anim := 0.0
var _defeat_anim := 0.0
var _power_anim := 0.0
var _hit_direction := 1.0
var _blink := 0.0
var _next_blink := 2.0
var _motion: Tween

func setup(id: int, name: String, animate_entrance: bool = true) -> void:
	world_id = clampi(id, 1, 10)
	boss_name = name
	_defeated = false
	_reacting = false
	modulate = Color.WHITE
	rotation = 0.0
	pivot_offset = custom_minimum_size * 0.5
	_enter_anim = 0.0 if animate_entrance else 1.0
	_hit_anim = 0.0
	_defeat_anim = 0.0
	_power_anim = 0.0
	_next_blink = 1.8 + float(posmod(world_id * 7, 10)) * 0.18
	set_process(true)
	if animate_entrance:
		_start_motion()
		_motion.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_motion.tween_property(self, "_enter_anim", 1.0, 0.62)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_power_anim = maxf(0.0, _power_anim - delta / 1.25)
	if not _defeated:
		_next_blink -= delta
		if _next_blink <= 0.0:
			_blink = 0.14
			_next_blink = 2.6 + float(posmod(int(_time * 10.0) + world_id * 3, 13)) * 0.16
		_blink = maxf(0.0, _blink - delta)
	queue_redraw()


func react_to_move() -> void:
	if _defeated:
		return
	_reacting = true
	_hit_direction = -_hit_direction
	queue_redraw()
	_start_motion()
	_motion.tween_property(self, "_hit_anim", 1.0, 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion.tween_property(self, "_hit_anim", 0.0, 0.38).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_motion.tween_callback(_finish_reaction)


func perform_power() -> void:
	if _defeated:
		return
	_power_anim = 1.0
	queue_redraw()


func celebrate_defeat() -> void:
	_defeated = true
	_reacting = false
	_hit_anim = 0.0
	_power_anim = 0.0
	queue_redraw()
	_start_motion()
	_motion.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion.tween_property(self, "_defeat_anim", 1.0, 0.92).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_motion.parallel().tween_property(self, "modulate:a", 0.0, 0.38).set_delay(0.53)


func reset_encounter() -> void:
	_defeated = false
	_reacting = false
	if is_instance_valid(_motion) and _motion.is_running():
		_motion.kill()
	_motion = null
	position = Vector2.ZERO
	rotation = 0.0
	modulate = Color.WHITE
	_enter_anim = 1.0
	_hit_anim = 0.0
	_defeat_anim = 0.0
	_power_anim = 0.0
	_next_blink = 2.0
	queue_redraw()


func _start_motion() -> void:
	if is_instance_valid(_motion) and _motion.is_running():
		_motion.kill()
	_motion = create_tween()


func _finish_reaction() -> void:
	_reacting = false
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	if side <= 0.0:
		return
	var screen_center := size * 0.5
	var radius := side * 0.39
	var world: Dictionary = State.worlds[world_id - 1]
	var color: Color = Palette.BULBS[int(world["color"])]
	var pulse := 0.035 * sin(_time * 2.8)
	_pixel_circle(screen_center, radius * (1.27 + pulse), Color(color, 0.10 + pulse * 0.5))
	_pixel_circle(screen_center, radius * (1.12 + pulse), Color(color, 0.20))
	_pixel_arc(screen_center, radius * (1.34 + pulse), 0.0, TAU, 48, Color(color, 0.3), 1.8, true)
	var idle_bob := sin(_time * 2.2) * 3.0 * _enter_anim
	var impact_bounce := sin((1.0 - _hit_anim) * PI) * 5.0 * _hit_anim
	var defeat_progress := clampf(_defeat_anim, 0.0, 1.0)
	var windup_squash := sin(clampf(defeat_progress / 0.16, 0.0, 1.0) * PI)
	var pop_progress := clampf((defeat_progress - 0.16) / 0.34, 0.0, 1.0)
	var defeat_pop := sin(pop_progress * PI)
	var dissolve_progress := clampf((defeat_progress - 0.52) / 0.42, 0.0, 1.0)
	var dissolve_eased := dissolve_progress * dissolve_progress * (3.0 - 2.0 * dissolve_progress)
	var tilt := sin(_time * 1.35) * 0.035 + _hit_direction * (_hit_anim * 0.16 + dissolve_eased * 1.05)
	var squash := (1.0 + _hit_anim * 0.18 + windup_squash * 0.28 + defeat_pop * 0.16) * (1.0 - dissolve_eased * 0.72) + sin(_time * 2.2) * 0.018
	var stretch := (1.0 - _hit_anim * 0.14 - windup_squash * 0.3 + defeat_pop * 0.12) * (1.0 - dissolve_eased * 0.76) - sin(_time * 2.2) * 0.018
	var defeat_lift := -defeat_pop * radius * 0.38 - dissolve_eased * radius * 0.55
	draw_set_transform(screen_center + Vector2(_hit_direction * (_hit_anim * 3.0 + dissolve_eased * radius * 0.22), idle_bob + impact_bounce + defeat_lift + 24.0 * (1.0 - _enter_anim)), tilt, Vector2(squash, stretch))
	var center := Vector2.ZERO
	match world_id:
		1:
			_draw_sleepy(center, radius, color)
		2:
			_draw_owl(center, radius, color)
		3:
			_draw_cloud(center, radius, color)
		4:
			_draw_chameleon(center, radius, color)
		5:
			_draw_twins(center, radius, color)
		6:
			_draw_octopus(center, radius, color)
		7:
			_draw_painter(center, radius, color)
		8:
			_draw_whale(center, radius, color)
		9:
			_draw_meteor(center, radius, color)
		10:
			_draw_queen(center, radius, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _hit_anim > 0.0:
		_pixel_arc(screen_center, radius * (1.1 + (1.0 - _hit_anim) * 0.42), 0.0, TAU, 36, Color(Palette.BULBS[2], _hit_anim * 0.8), maxf(1.5, radius * 0.045), true)
	_draw_power_effect(screen_center, radius, color)
	_draw_ambient_stars(screen_center, radius, color)
	if _defeated:
		_draw_victory_burst(screen_center, radius)


func _draw_power_effect(center: Vector2, radius: float, color: Color) -> void:
	if _power_anim <= 0.0:
		return
	var progress := 1.0 - _power_anim
	var fade := sin(progress * PI)
	var spread := lerpf(0.35, 1.5, progress)
	var ink := Color(color.lightened(0.45), fade)
	match world_id:
		1:
			for i in 3:
				var rise := progress * radius * (0.65 + float(i) * 0.22)
				var x := center.x + (float(i) - 1.0) * radius * 0.32
				_pixel_line(Vector2(x - 3.0, center.y - rise), Vector2(x + 3.0, center.y - rise - 5.0), Color(Palette.BULBS[1], fade), 2.0, true)
		2:
			var scan_angle := _time * 5.0
			_pixel_arc(center, radius * (0.9 + spread * 0.5), scan_angle, scan_angle + PI * 0.72, 28, ink, maxf(2.0, radius * 0.07), true)
			_pixel_circle(center + Vector2(cos(scan_angle) * radius * spread, sin(scan_angle) * radius * spread), radius * 0.075 * fade, Palette.BULBS[1])
		3:
			for i in 3:
				var puff_side := float(i - 1)
				var puff_center := center + Vector2(puff_side * radius * spread * 0.72, -radius * 0.28 - absf(puff_side) * radius * 0.12)
				_pixel_circle(puff_center, radius * (0.2 + 0.08 * fade), Color(Palette.BASE, fade * 0.72))
		4:
			for i in 5:
				var color_angle := TAU * float(i) / 5.0 + _time * 1.4
				var dot := center + Vector2(cos(color_angle), sin(color_angle)) * radius * spread
				_pixel_circle(dot, radius * 0.075 * fade, Palette.BULBS[i % Palette.BULBS.size()])
		5:
			for side in [-1.0, 1.0]:
				var twin_center := center + Vector2(side * radius * 0.28, 0)
				_pixel_arc(twin_center, radius * spread, 0.0, TAU, 32, ink, maxf(1.5, radius * 0.045), true)
		6:
			_draw_bolt(center + Vector2(-radius * spread, -radius * 0.55), radius * 0.24 * fade, Palette.BULBS[1])
			_draw_bolt(center + Vector2(radius * spread, radius * 0.35), radius * 0.2 * fade, Palette.BULBS[2])
		7:
			for i in 5:
				var paint_angle := TAU * float(i) / 5.0 - PI * 0.5
				var splash := center + Vector2(cos(paint_angle), sin(paint_angle)) * radius * spread
				_pixel_circle(splash, radius * (0.07 + 0.025 * float(i % 2)) * fade, Palette.BULBS[i % Palette.BULBS.size()])
			_pixel_line(center + Vector2(radius * 0.48, radius * 0.48), center + Vector2(radius * spread, radius * 0.72), Palette.BULBS[3], maxf(2.0, radius * 0.07 * fade), true)
		8:
			for i in 3:
				var wave_radius := radius * (0.78 + float(i) * 0.2 + progress * 0.45)
				_pixel_arc(center, wave_radius, PI * 0.12, PI * 0.88, 24, Color(Palette.BULBS[2], fade * (1.0 - float(i) * 0.18)), maxf(1.5, radius * 0.05), true)
		9:
			var tail := center + Vector2(-radius * spread, -radius * spread * 0.55)
			_pixel_line(tail, center + Vector2(radius * 0.35, radius * 0.15), Color(Palette.BULBS[1], fade), maxf(2.0, radius * 0.18 * fade), true)
			_draw_star(tail, radius * 0.2 * fade, Palette.BULBS[1])
		10:
			_pixel_arc(center, radius * (1.0 + spread * 0.38), 0.0, TAU, 40, Color(Palette.BG, fade * 0.8), maxf(3.0, radius * 0.13), true)
			for i in 8:
				var eclipse_angle := TAU * float(i) / 8.0 + _time * 0.3
				var inner := center + Vector2(cos(eclipse_angle), sin(eclipse_angle)) * radius * 1.12
				var outer := center + Vector2(cos(eclipse_angle), sin(eclipse_angle)) * radius * spread
				_pixel_line(inner, outer, Color(Palette.BULBS[3], fade * 0.8), maxf(1.5, radius * 0.035), true)


func _pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius, color)


func _pixel_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, point_count: int, color: Color, width: float, _antialiased := false) -> void:
	draw_arc(center, radius, start_angle, end_angle, point_count, color, width, true)


func _pixel_line(from: Vector2, to: Vector2, color: Color, width: float, _antialiased := false) -> void:
	draw_line(from, to, color, width, true)


func _pixel_polygon(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)


func _draw_base(center: Vector2, radius: float, color: Color) -> void:
	_pixel_circle(center, radius, color.lightened(0.12) if _reacting else color)
	_pixel_arc(center, radius, 0.0, TAU, 48, Color(Palette.FACE, 0.2), maxf(1.0, radius * 0.035), true)
	_pixel_circle(center + Vector2(-radius * 0.34, -radius * 0.36), radius * 0.17, Color(1, 1, 1, 0.38))
	_draw_face(center, radius)


func _draw_sleepy(center: Vector2, radius: float, color: Color) -> void:
	_pixel_circle(center, radius, color.lightened(0.12) if _reacting else color)
	_pixel_circle(center + Vector2(-radius * 0.34, -radius * 0.36), radius * 0.17, Color(1, 1, 1, 0.38))
	for side in [-1.0, 1.0]:
		var eye := center + Vector2(side * radius * 0.34, -radius * 0.04)
		_pixel_arc(eye, radius * 0.12, 0.15, PI - 0.15, 12, Palette.FACE, maxf(2.0, radius * 0.08), true)
	_pixel_arc(center + Vector2(0, radius * 0.08), radius * 0.17, 0.15, PI - 0.15, 16, Palette.FACE, maxf(1.5, radius * 0.07), true)
	_pixel_circle(center + Vector2(-radius * 0.62, radius * 0.24), radius * 0.12, Color(Palette.BLUSH, 0.7))
	_pixel_circle(center + Vector2(radius * 0.62, radius * 0.24), radius * 0.12, Color(Palette.BLUSH, 0.7))
	_pixel_arc(center + Vector2(0, -radius * 0.72), radius * 0.48, PI, TAU, 28, Palette.BULBS[2], maxf(3.0, radius * 0.16), true)
	_pixel_polygon(PackedVector2Array([
		center + Vector2(-radius * 0.32, -radius * 0.8), center + Vector2(radius * 0.48, -radius * 1.02),
		center + Vector2(radius * 0.18, -radius * 0.58),
	]), Palette.BULBS[2])
	_draw_star(center + Vector2(radius * 0.48, -radius * 0.9), radius * 0.15, Palette.BULBS[1])


func _draw_owl(center: Vector2, radius: float, color: Color) -> void:
	_pixel_polygon(PackedVector2Array([center + Vector2(-radius * 0.78, -radius * 0.42), center + Vector2(-radius * 0.56, -radius * 1.18), center + Vector2(-radius * 0.08, -radius * 0.75)]), color.darkened(0.12))
	_pixel_polygon(PackedVector2Array([center + Vector2(radius * 0.78, -radius * 0.42), center + Vector2(radius * 0.56, -radius * 1.18), center + Vector2(radius * 0.08, -radius * 0.75)]), color.darkened(0.12))
	_pixel_circle(center + Vector2(-radius * 0.66, radius * 0.1), radius * 0.36, color.lightened(0.12))
	_pixel_circle(center + Vector2(radius * 0.66, radius * 0.1), radius * 0.36, color.lightened(0.12))
	_pixel_circle(center, radius, color.lightened(0.12) if _reacting else color)
	_pixel_arc(center, radius, 0.0, TAU, 48, Color(Palette.FACE, 0.2), maxf(1.0, radius * 0.035), true)
	_pixel_circle(center + Vector2(-radius * 0.34, -radius * 0.36), radius * 0.17, Color(1, 1, 1, 0.38))
	for side in [-1.0, 1.0]:
		var eye_center := center + Vector2(side * radius * 0.32, -radius * 0.02)
		if _defeated or _blink > 0.0:
			_pixel_arc(eye_center + Vector2(0, radius * 0.03), radius * 0.15, PI, TAU, 16, Palette.FACE, maxf(2.0, radius * 0.075), true)
		else:
			_pixel_circle(eye_center, radius * 0.19, Color.WHITE)
			var pupil_radius := radius * (0.1 if _reacting else 0.075)
			_pixel_circle(eye_center + Vector2(0, radius * 0.015), pupil_radius, Palette.FACE)
			_pixel_circle(eye_center + Vector2(-pupil_radius * 0.25, -pupil_radius * 0.3), pupil_radius * 0.25, Color.WHITE)
	_pixel_polygon(PackedVector2Array([center + Vector2(-radius * 0.12, radius * 0.22), center + Vector2(radius * 0.12, radius * 0.22), center + Vector2(0, radius * 0.42)]), Palette.BULBS[2])
	_draw_star(center + Vector2(0, -radius * 1.04), radius * 0.17, Palette.BULBS[1])


func _draw_cloud(center: Vector2, radius: float, color: Color) -> void:
	for offset in [Vector2(-0.54, -0.43), Vector2(-0.25, -0.77), Vector2(0.18, -0.78), Vector2(0.53, -0.42)]:
		_pixel_circle(center + offset * radius, radius * 0.43, Color(1, 1, 1, 0.88))
	_pixel_circle(center, radius * 0.88, color.lightened(0.16))
	_draw_face(center, radius * 0.78)
	_pixel_circle(center + Vector2(-radius * 0.72, radius * 0.72), radius * 0.09, Palette.BULBS[2])
	_pixel_circle(center + Vector2(0, radius * 0.84), radius * 0.09, Palette.BULBS[2])
	_pixel_circle(center + Vector2(radius * 0.72, radius * 0.72), radius * 0.09, Palette.BULBS[2])


func _draw_chameleon(center: Vector2, radius: float, color: Color) -> void:
	_pixel_arc(center + Vector2(-radius * 0.72, radius * 0.42), radius * 0.48, PI * 0.2, PI * 1.8, 32, color.lightened(0.2), maxf(3.0, radius * 0.18), true)
	_pixel_circle(center + Vector2(-radius * 0.62, -radius * 0.56), radius * 0.2, color)
	_pixel_circle(center + Vector2(radius * 0.62, -radius * 0.56), radius * 0.2, color)
	_draw_base(center, radius, color)
	_pixel_circle(center + Vector2(radius * 0.98, radius * 0.12), radius * 0.32, color.lightened(0.12))
	for offset in [Vector2(-0.55, 0.15), Vector2(0.25, 0.48), Vector2(0.54, -0.35)]:
		_pixel_circle(center + offset * radius, radius * 0.1, Palette.BULBS[2])


func _draw_twins(center: Vector2, radius: float, color: Color) -> void:
	var twin_radius := radius * 0.66
	var twin_bob := sin(_time * 2.8) * radius * 0.035
	var left := center + Vector2(-radius * 0.42, twin_bob)
	var right := center + Vector2(radius * 0.42, -twin_bob)
	_pixel_circle(left, twin_radius, color.lightened(0.18))
	_pixel_circle(right, twin_radius, color.darkened(0.08))
	_draw_face(left, twin_radius * 0.78)
	_draw_face(right, twin_radius * 0.78)
	_pixel_arc(center, radius * 1.16, PI * 0.12, PI * 0.88, 32, Color(Palette.BULBS[2], 0.85), maxf(2.0, radius * 0.07), true)


func _draw_octopus(center: Vector2, radius: float, color: Color) -> void:
	for i in 5:
		var x_offset := (float(i) - 2.0) * radius * 0.34
		var start := center + Vector2(x_offset * 0.72, radius * 0.58)
		var wiggle := sin(_time * 4.0 + float(i) * 0.8) * radius * 0.1
		var end := center + Vector2(x_offset + wiggle, radius * (1.0 + 0.08 * (i % 2)))
		_pixel_line(start, end, color, maxf(4.0, radius * 0.2), true)
		_pixel_circle(end, radius * 0.09, Palette.BULBS[1])
	_pixel_circle(center, radius * 0.9, color)
	_draw_face(center, radius * 0.82)
	_draw_bolt(center + Vector2(radius * 0.76, -radius * 0.75), radius * 0.3, Palette.BULBS[2])


func _draw_painter(center: Vector2, radius: float, color: Color) -> void:
	_pixel_circle(center, radius, color)
	_draw_face(center, radius * 0.86)
	_pixel_arc(center + Vector2(0, -radius * 0.52), radius * 0.62, PI, TAU, 28, Palette.BULBS[3], maxf(4.0, radius * 0.2), true)
	for i in 3:
		_pixel_circle(center + Vector2((float(i) - 1.0) * radius * 0.36, -radius * 0.89), radius * 0.12, Palette.BULBS[i])
	var brush_tip := center + Vector2(radius * (1.04 + sin(_time * 2.3) * 0.08), radius * (0.95 + cos(_time * 2.3) * 0.05))
	_pixel_line(center + Vector2(radius * 0.72, radius * 0.52), brush_tip, Palette.BULBS[2], maxf(3.0, radius * 0.1), true)


func _draw_whale(center: Vector2, radius: float, color: Color) -> void:
	_pixel_polygon(PackedVector2Array([center + Vector2(-radius * 0.72, radius * 0.1), center + Vector2(-radius * 1.24, -radius * 0.38), center + Vector2(-radius * 1.18, radius * 0.52)]), color.darkened(0.1))
	var body := PackedVector2Array()
	for i in 20:
		var angle := TAU * float(i) / 20.0
		body.append(center + Vector2(cos(angle) * radius * 1.12, sin(angle) * radius * 0.78))
	_pixel_polygon(body, color)
	_pixel_circle(center + Vector2(radius * 0.62, radius * 0.18), radius * 0.07, Palette.FACE)
	_pixel_arc(center + Vector2(0, -radius * 0.76), radius * 0.35, PI, TAU, 24, Palette.BULBS[2], maxf(2.0, radius * 0.12), true)
	var bubble_rise := fposmod(_time * 0.22, 1.0)
	_pixel_circle(center + Vector2(-radius * 0.12, -radius * (0.88 + bubble_rise * 0.34)), radius * 0.08, Color(Palette.BULBS[2], 0.9 - bubble_rise * 0.25))
	_pixel_circle(center + Vector2(radius * 0.14, -radius * (0.98 + fposmod(bubble_rise + 0.5, 1.0) * 0.3)), radius * 0.06, Color(Palette.BULBS[2], 0.75))
	_pixel_circle(center + Vector2(-radius * 0.2, radius * 0.44), radius * 0.22, Color(1, 1, 1, 0.68))


func _draw_meteor(center: Vector2, radius: float, color: Color) -> void:
	for i in 4:
		var start := center + Vector2(-radius * (0.72 + i * 0.1), -radius * (0.45 - i * 0.3))
		var tip := center + Vector2(-radius * (1.65 + i * 0.1), -radius * (0.42 - i * 0.28))
		var trail_width := maxf(3.0, radius * (0.2 - i * 0.025) * (0.82 + 0.18 * sin(_time * 7.0 + i)))
		_pixel_line(start, tip, Palette.BULBS[2] if i % 2 == 0 else Palette.BULBS[0], trail_width, true)
	_pixel_circle(center, radius * 0.84, color)
	_draw_face(center, radius * 0.76)
	_draw_star(center + Vector2(radius * 0.43, -radius * 0.46), radius * 0.14, Palette.BULBS[1])


func _draw_queen(center: Vector2, radius: float, color: Color) -> void:
	_pixel_polygon(PackedVector2Array([
		center + Vector2(-radius * 0.72, radius * 0.35), center + Vector2(-radius * 1.0, radius * 1.13),
		center + Vector2(radius * 1.0, radius * 1.13), center + Vector2(radius * 0.72, radius * 0.35),
	]), color.darkened(0.28))
	_pixel_circle(center, radius * 0.84, color.darkened(0.1))
	_draw_face(center, radius * 0.76)
	_draw_star(center + Vector2(-radius * 0.62, -radius * 0.88), radius * 0.24, Palette.BULBS[2])
	_draw_star(center + Vector2(0, -radius * 1.08), radius * 0.31, Palette.BULBS[1])
	_draw_star(center + Vector2(radius * 0.62, -radius * 0.88), radius * 0.24, Palette.BULBS[2])


func _draw_face(center: Vector2, radius: float) -> void:
	var face := Palette.FACE
	var eye_y := center.y - radius * 0.04
	var eye_dx := radius * 0.34
	if _defeated:
		for side in [-1.0, 1.0]:
			var eye := Vector2(center.x + eye_dx * side, eye_y)
			_pixel_arc(eye + Vector2(0, radius * 0.06), radius * 0.12, PI, TAU, 12, face, maxf(2.0, radius * 0.09), true)
	elif _reacting:
		_pixel_circle(Vector2(center.x - eye_dx, eye_y), radius * 0.12, face)
		_pixel_circle(Vector2(center.x + eye_dx, eye_y), radius * 0.12, face)
		_pixel_circle(center + Vector2(0, radius * 0.22), radius * 0.1, face)
	elif _blink > 0.0:
		for side in [-1.0, 1.0]:
			var eye := Vector2(center.x + eye_dx * side, eye_y)
			_pixel_line(eye + Vector2(-radius * 0.1, 0), eye + Vector2(radius * 0.1, 0), face, maxf(2.0, radius * 0.08), true)
	else:
		_pixel_circle(Vector2(center.x - eye_dx, eye_y), radius * 0.09, face)
		_pixel_circle(Vector2(center.x + eye_dx, eye_y), radius * 0.09, face)
	if not _reacting:
		_pixel_arc(center + Vector2(0, radius * 0.08), radius * (0.2 if not _defeated else 0.24), 0.15, PI - 0.15, 16, face, maxf(1.5, radius * 0.07), true)
	_pixel_circle(center + Vector2(-radius * 0.62, radius * 0.24), radius * 0.12, Color(Palette.BLUSH, 0.7))
	_pixel_circle(center + Vector2(radius * 0.62, radius * 0.24), radius * 0.12, Color(Palette.BLUSH, 0.7))


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI * 0.5 + TAU * float(i) / 10.0
		var point_radius := radius if i % 2 == 0 else radius * 0.45
		points.append(center + Vector2(cos(angle), sin(angle)) * point_radius)
	_pixel_polygon(points, color)


func _draw_ambient_stars(center: Vector2, radius: float, color: Color) -> void:
	for i in 3:
		var angle := _time * (0.55 + i * 0.13) + TAU * float(i) / 3.0
		var orbit := radius * (1.18 + 0.08 * sin(_time * 1.7 + i))
		var sparkle_center := center + Vector2(cos(angle), sin(angle)) * orbit
		var sparkle_radius := radius * (0.045 + 0.018 * float(i % 2))
		_pixel_line(sparkle_center - Vector2(sparkle_radius, 0), sparkle_center + Vector2(sparkle_radius, 0), Color(color.lightened(0.35), 0.75), 1.5, true)
		_pixel_line(sparkle_center - Vector2(0, sparkle_radius), sparkle_center + Vector2(0, sparkle_radius), Color(color.lightened(0.35), 0.75), 1.5, true)


func _draw_victory_burst(center: Vector2, radius: float) -> void:
	var progress := clampf(_defeat_anim, 0.0, 1.0)
	var ring_progress := clampf(progress / 0.55, 0.0, 1.0)
	var ring_radius := radius * lerpf(0.65, 2.05, ring_progress)
	var ring_alpha := (1.0 - ring_progress) * 0.75
	if ring_alpha > 0.0:
		_pixel_arc(center, ring_radius, 0.0, TAU, 48, Color(Palette.BULBS[1], ring_alpha), maxf(2.0, radius * 0.055 * (1.0 - ring_progress * 0.45)), true)
	for i in 10:
		var angle := TAU * float(i) / 10.0 - PI * 0.5 + _time * 0.2
		var burst := clampf((progress - 0.2) / 0.72, 0.0, 1.0)
		var distance := radius * (0.28 + burst * (1.3 + 0.22 * sin(float(i) * 2.0)))
		var sparkle_center := center + Vector2(cos(angle), sin(angle)) * distance
		var sparkle_color: Color = Palette.BULBS[i % Palette.BULBS.size()]
		var sparkle_alpha := clampf((progress - 0.18) / 0.18, 0.0, 1.0) * (1.0 - burst * 0.55)
		var sparkle_size := radius * (0.15 - burst * 0.055)
		_draw_star(sparkle_center, sparkle_size, Color(sparkle_color, sparkle_alpha))
		var trail_start := center + Vector2(cos(angle), sin(angle)) * distance * 0.58
		_pixel_line(trail_start, sparkle_center, Color(sparkle_color, sparkle_alpha * 0.42), maxf(1.0, radius * 0.035), true)


func _draw_bolt(center: Vector2, radius: float, color: Color) -> void:
	_pixel_polygon(PackedVector2Array([
		center + Vector2(0, -radius), center + Vector2(radius * 0.35, -radius * 0.12),
		center + Vector2(radius * 0.05, -radius * 0.12), center + Vector2(radius * 0.2, radius),
		center + Vector2(-radius * 0.42, radius * 0.08), center + Vector2(-radius * 0.1, radius * 0.08),
	]), color)

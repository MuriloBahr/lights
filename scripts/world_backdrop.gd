class_name WorldBackdrop
extends Control

var world_id := 1
var level_id := 0
var _visual_theme := 0


func setup(id: int, phase_id := 0, theme_id := 0) -> void:
	world_id = clampi(id, 1, 10)
	level_id = phase_id
	_visual_theme = clampi(theme_id, 0, 3)
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var top: Color
	var bottom: Color
	var accent: Color = Palette.BULBS[posmod(world_id - 1, Palette.BULBS.size())]
	match world_id:
		1:
			top = Color("201b3e")
			bottom = Color("49305f")
		2:
			top = Color("14283f")
			bottom = Color("25496a")
		3:
			top = Color("173a3e")
			bottom = Color("286657")
		4:
			top = Color("29234b")
			bottom = Color("4a386c")
		5:
			top = Color("29223f")
			bottom = Color("55406b")
		6:
			top = Color("3b263c")
			bottom = Color("714454")
		7:
			top = Color("49304c")
			bottom = Color("925b79")
		8:
			top = Color("17394a")
			bottom = Color("397e83")
		9:
			top = Color("25224f")
			bottom = Color("514d8a")
		10:
			top = Color("3b204c")
			bottom = Color("9a477d")
		_:
			top = Palette.BG
			bottom = Palette.BG

	var level_washes := [Color("ffd9e8"), Color("c8ecff"), Color("ddf6c8"), Color("ffe4bd")]
	var wash: Color = level_washes[posmod(level_id, level_washes.size())]
	top = top.lerp(wash, 0.10).lerp(accent, float(level_id % 6) * 0.012)
	bottom = bottom.lerp(wash, 0.16).lerp(accent, float(level_id % 6) * 0.018)
	match _visual_theme:
		1:
			top = top.lerp(Color("d65d9d"), 0.34)
			bottom = bottom.lerp(Color("ffb6d7"), 0.28)
		2:
			top = top.lerp(Color("397b72"), 0.32)
			bottom = bottom.lerp(Color("a1edce"), 0.26)
		3:
			top = top.lerp(Color("343e79"), 0.38)
			bottom = bottom.lerp(Color("a3baff"), 0.28)
	var bands := maxi(1, ceili(size.y / 32.0))
	for i in bands:
		var y0 := size.y * float(i) / bands
		var y1 := size.y * float(i + 1) / bands
		draw_rect(Rect2(0, y0, size.x, y1 - y0 + 1.0), top.lerp(bottom, float(i) / bands))

	draw_circle(Vector2(size.x * 0.12, size.y * 0.18), size.x * 0.48, Color(accent, 0.045))
	draw_circle(Vector2(size.x * 0.9, size.y * 0.82), size.x * 0.42, Color(accent, 0.035))
	_draw_world_motif(accent)
	_draw_cute_decor(accent)
	_draw_sparkles(accent)


func _draw_world_motif(accent: Color) -> void:
	var w := size.x
	var h := size.y
	var line_color := Color(accent, 0.12)
	match world_id:
		1:
			for i in 3:
				var radius := w * (0.18 + i * 0.09)
				draw_arc(Vector2(w * 0.84, h * 0.18), radius, 0.2, 2.4, 48, line_color, 2.0, true)
		2:
			for i in 7:
				var d := float(i) * 34.0
				draw_line(Vector2(w * 0.72 + d, 0), Vector2(w * 0.72 - h * 0.55 + d, h * 0.55), line_color, 2.0)
				draw_line(Vector2(0, h * 0.72 + d), Vector2(w * 0.38, h * 0.72 - d), line_color, 2.0)
		3:
			for i in 5:
				var x := w * (0.12 + 0.19 * i)
				var y := h * (0.16 + 0.055 * (i % 2))
				draw_circle(Vector2(x, y), 14.0 + 5.0 * (i % 3), Color(accent, 0.07))
				draw_arc(Vector2(x, y), 23.0 + 5.0 * (i % 3), 0.0, TAU, 32, line_color, 1.5, true)
		4:
			for i in 4:
				_draw_diamond(Vector2(w * (0.14 + 0.23 * i), h * 0.84), 18.0 + 5.0 * i, line_color)
		5:
			var center := Vector2(w * 0.5, h * 0.48)
			for i in 4:
				draw_arc(center, w * (0.16 + i * 0.095), 0.0, TAU, 56, line_color, 1.5, true)
			draw_line(Vector2(w * 0.5, 0), Vector2(w * 0.5, h), Color(accent, 0.09), 1.5)
		6:
			var origin := Vector2(w * 0.5, h * 0.5)
			for i in 12:
				var angle := TAU * float(i) / 12.0
				var direction := Vector2(cos(angle), sin(angle))
				draw_line(origin + direction * w * 0.18, origin + direction * w * 0.78, Color(accent, 0.08), 2.0)
		7:
			for i in 6:
				var center := Vector2(w * (0.12 + 0.16 * i), h * (0.16 + 0.04 * (i % 2)))
				draw_circle(center + Vector2(-6, 0), 12.0, Color(accent, 0.10))
				draw_circle(center + Vector2(6, 0), 12.0, Color(accent, 0.10))
				draw_colored_polygon(PackedVector2Array([center + Vector2(-17, 3), center + Vector2(17, 3), center + Vector2(0, 23)]), Color(accent, 0.10))
		8:
			for i in 5:
				var y := h * (0.16 + 0.15 * i)
				draw_arc(Vector2(w * 0.5, y), w * 0.32, 0.1, PI - 0.1, 48, Color(accent, 0.12), 3.0, true)
		9:
			for i in 7:
				var x := w * (0.08 + 0.14 * i)
				draw_line(Vector2(x, h * 0.08), Vector2(x - w * 0.08, h * 0.25), Color(accent, 0.10), 2.0, true)
		10:
			var center := Vector2(w * 0.5, h * 0.46)
			for i in 5:
				draw_arc(center, w * (0.12 + i * 0.075), 0.0, TAU, 56, Color(accent, 0.10), 2.0, true)


func _draw_cute_decor(accent: Color) -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var phase := posmod(level_id, 4)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(level_id) * 731 + world_id * 97
	for i in 14:
		var center := Vector2(rng.randf_range(0.04, 0.96) * w, rng.randf_range(0.07, 0.94) * h)
		var radius := rng.randf_range(3.0, 9.0)
		draw_circle(center, radius, Color(Palette.FACE, 0.045))
		if i % 3 == phase % 3:
			_draw_sparkle(center, radius * 0.7, Color(accent, 0.22))

	var side := -1.0 if phase % 2 == 0 else 1.0
	var buddy_a := Vector2(w * (0.10 if side < 0.0 else 0.90), h * (0.25 + 0.035 * phase))
	var buddy_b := Vector2(w * (0.88 if side < 0.0 else 0.12), h * (0.72 - 0.025 * phase))
	_draw_lamp_buddy(buddy_a, minf(w * 0.047, 23.0), accent)
	if phase == 1 or phase == 3:
		_draw_lamp_buddy(buddy_b, minf(w * 0.035, 17.0), Palette.BULBS[(world_id + 2) % Palette.BULBS.size()])

	var hill_color := Color(accent, 0.045)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, h * 0.94), Vector2(w * 0.22, h * 0.89), Vector2(w * 0.43, h * 0.95),
		Vector2(w * 0.67, h * 0.90), Vector2(w, h * 0.95), Vector2(w, h), Vector2(0, h),
	]), hill_color)


func _draw_lamp_buddy(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius * 1.45, Color(color, 0.045))
	draw_circle(center, radius, Color(color, 0.16))
	draw_arc(center, radius, 0.0, TAU, 36, Color(color, 0.22), 1.5, true)
	draw_circle(center + Vector2(-radius * 0.30, -radius * 0.08), radius * 0.075, Color(Palette.FACE, 0.68))
	draw_circle(center + Vector2(radius * 0.30, -radius * 0.08), radius * 0.075, Color(Palette.FACE, 0.68))
	draw_arc(center + Vector2(0, radius * 0.02), radius * 0.27, 0.25, PI - 0.25, 12, Color(Palette.FACE, 0.62), maxf(1.0, radius * 0.065), true)
	draw_line(center + Vector2(-radius * 0.28, radius * 0.74), center + Vector2(radius * 0.28, radius * 0.74), Color(color, 0.16), 2.0, true)


func _draw_sparkle(center: Vector2, radius: float, color: Color) -> void:
	draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), color, 1.5, true)
	draw_line(center - Vector2(0, radius), center + Vector2(0, radius), color, 1.5, true)


func _draw_sparkles(accent: Color) -> void:
	var points := [
		Vector2(0.1, 0.1), Vector2(0.32, 0.2), Vector2(0.75, 0.12), Vector2(0.92, 0.28),
		Vector2(0.18, 0.42), Vector2(0.86, 0.52), Vector2(0.08, 0.7), Vector2(0.73, 0.78),
		Vector2(0.3, 0.9), Vector2(0.94, 0.92), Vector2(0.52, 0.08), Vector2(0.48, 0.94),
	]
	for i in points.size():
		var p: Vector2 = points[i]
		p.x = fposmod(p.x + float(level_id % 4) * 0.018, 1.0)
		var center := Vector2(p.x * size.x, p.y * size.y)
		var radius := 2.0 + float((i + level_id) % 3)
		draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), Color(accent, 0.28), 1.5)
		draw_line(center - Vector2(0, radius), center + Vector2(0, radius), Color(accent, 0.28), 1.5)


func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
	draw_polyline(PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius, 0),
		center + Vector2(0, -radius),
	]), color, 2.0, true)

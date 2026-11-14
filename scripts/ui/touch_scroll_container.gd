class_name TouchScrollContainer
extends ScrollContainer

const DRAG_THRESHOLD := 12.0
const MOMENTUM_FRICTION := 4.8
const MIN_MOMENTUM := 18.0

var _touch_index := -1
var _touch_origin := Vector2.ZERO
var _scroll_origin := 0
var _dragging := false
var _scroll_velocity := 0.0
var _last_event_time := 0


func _ready() -> void:
	# The shared gesture starts before a child button can swallow a drag.
	scroll_deadzone = 64
	set_process(false)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if get_global_rect().has_point(touch.position):
				_scroll_velocity = 0.0
				set_process(false)
				_touch_index = touch.index
				_touch_origin = touch.position
				_scroll_origin = scroll_vertical
				_last_event_time = Time.get_ticks_msec()
				_dragging = false
		elif touch.index == _touch_index:
			if _dragging:
				get_viewport().set_input_as_handled()
				if absf(_scroll_velocity) > 90.0:
					set_process(true)
			_touch_index = -1
			_dragging = false
		return

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != _touch_index:
			return
		var distance_y := drag.position.y - _touch_origin.y
		if not _dragging and absf(distance_y) >= DRAG_THRESHOLD:
			_dragging = true
		if not _dragging:
			return

		var previous_scroll := scroll_vertical
		scroll_vertical = _scroll_origin - roundi(distance_y)
		var now := Time.get_ticks_msec()
		var elapsed := maxf(0.001, float(now - _last_event_time) / 1000.0)
		var instant_velocity := float(scroll_vertical - previous_scroll) / elapsed
		_scroll_velocity = lerpf(_scroll_velocity, instant_velocity, 0.4)
		_last_event_time = now
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _touch_index >= 0:
		return
	if absf(_scroll_velocity) < MIN_MOMENTUM:
		_stop_momentum()
		return
	var previous_scroll := scroll_vertical
	scroll_vertical += roundi(_scroll_velocity * delta)
	if scroll_vertical == previous_scroll:
		_stop_momentum()
		return
	_scroll_velocity *= exp(-MOMENTUM_FRICTION * delta)


func _stop_momentum() -> void:
	_scroll_velocity = 0.0
	set_process(false)

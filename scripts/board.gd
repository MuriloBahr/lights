class_name Board
extends RefCounted

signal changed
signal solved

const DIRS = [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var size := 0
var cells := PackedByteArray()
var initial := PackedByteArray()
var moves: Array[Vector2i] = []


func load_level(level: Dictionary) -> void:
	size = int(level["size"])
	initial.resize(size * size)
	for i in initial.size():
		initial[i] = int(level["grid"][i])
	reset()


func reset() -> void:
	cells = initial.duplicate()
	moves.clear()
	changed.emit()


func get_cell(x: int, y: int) -> int:
	return cells[y * size + x]


func toggle(x: int, y: int) -> void:
	var p := Vector2i(x, y)
	_apply(p)
	moves.append(p)
	changed.emit()
	if is_solved():
		solved.emit()


func undo() -> void:
	if moves.is_empty():
		return
	_apply(moves.pop_back())
	changed.emit()


func is_solved() -> bool:
	for c in cells:
		if c != 0:
			return false
	return true


func _apply(p: Vector2i) -> void:
	for d in DIRS:
		var q: Vector2i = p + d
		if q.x >= 0 and q.x < size and q.y >= 0 and q.y < size:
			cells[q.y * size + q.x] ^= 1
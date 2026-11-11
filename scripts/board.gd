class_name Board
extends RefCounted

signal changed
signal solved

const SHAPES := {
	"plus": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)],
	"x": [Vector2i(0, 0), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)],
}

var size := 0
var cells := PackedByteArray()
var initial := PackedByteArray()
var active := PackedByteArray()
var offsets: Array = SHAPES["plus"]
var effect := "none"
var moves: Array[Vector2i] = []
var last_touched: Array[int] = []


func load_level(level: Dictionary) -> void:
	size = int(level["size"])
	effect = String(level.get("effect", "none"))
	offsets = SHAPES[level.get("shape", "plus")]
	var mask: Array = level.get("mask", [])
	active.resize(size * size)
	initial.resize(size * size)
	for i in size * size:
		active[i] = 1 if mask.is_empty() else int(mask[i])
		initial[i] = int(level["grid"][i])
	reset()


func reset() -> void:
	cells = initial.duplicate()
	moves.clear()
	last_touched.clear()
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
	last_touched = affected_cells(p.x, p.y)
	for index in last_touched:
		cells[index] ^= 1


func affected_cells(x: int, y: int) -> Array[int]:
	var p := Vector2i(x, y)
	var touched: Dictionary = {}
	for d in offsets:
		var q: Vector2i = p + d
		_mark(touched, q)
	_apply_effect(p, touched)
	var indices: Array[int] = []
	for i in touched.keys():
		indices.append(int(i))
	return indices


func _mark(touched: Dictionary, pos: Vector2i) -> void:
	if pos.x < 0 or pos.x >= size or pos.y < 0 or pos.y >= size:
		return
	var i := pos.y * size + pos.x
	if active[i] == 1:
		touched[i] = true


func _apply_effect(p: Vector2i, touched: Dictionary) -> void:
	match effect:
		"mirror":
			_mark(touched, Vector2i(size - 1 - p.x, size - 1 - p.y))
		"line":
			for x in range(size):
				_mark(touched, Vector2i(x, p.y))
			for y in range(size):
				_mark(touched, Vector2i(p.x, y))

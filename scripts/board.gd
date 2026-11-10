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
var moves: Array[Vector2i] = []


func load_level(level: Dictionary) -> void:
	size = int(level["size"])
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
	for d in offsets:
		var q: Vector2i = p + d
		if q.x < 0 or q.x >= size or q.y < 0 or q.y >= size:
			continue
		var i := q.y * size + q.x
		if active[i] == 1:
			cells[i] ^= 1
extends RefCounted

class_name WalkerRoom

# Drunkard's-walk generator. Carves a connected set of floor cells by stepping
# in a random direction, turning every STEPS_PER_ROOM steps and stamping a room
# at each turn.
#
# Every cell this produces is guaranteed to be strictly inside `borders`, so the
# caller can rely on the border ring staying solid.

const DIRECTIONS = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]
const STEPS_PER_ROOM := 7

var position := Vector2.ZERO
var direction := Vector2.RIGHT
var borders := Rect2()
var step_history: Array[Vector2] = []

var steps_since_turn := 0
var rooms := []

# Same cells as step_history, as a set, for O(1) membership tests.
# The array alone would force callers into an O(n) scan per lookup.
var _visited := {}

func _init(starting_position: Vector2, new_borders: Rect2) -> void:
	assert(new_borders.has_point(starting_position),
		"Walker start %s is outside borders %s" % [starting_position, new_borders])
	borders = new_borders
	position = starting_position
	_mark(position)

func walk(steps: int) -> Array[Vector2]:
	place_room(position)

	for _i in steps:
		if steps_since_turn >= STEPS_PER_ROOM:
			change_direction()
		if step():
			_mark(position)
		else:
			change_direction()
	return step_history

# Records a floor cell, skipping duplicates. Rooms overlap constantly, and
# without this the history carried the same cell many times over -- which both
# bloated the array and skewed pick_random() toward heavily-overlapped tiles.
func _mark(cell: Vector2) -> void:
	if not _visited.has(cell):
		_visited[cell] = true
		step_history.append(cell)

# O(1) lookup set of every carved cell.
func get_floor_lookup() -> Dictionary:
	return _visited

func step() -> bool:
	var target_position := position + direction
	if borders.has_point(target_position):
		steps_since_turn += 1
		position = target_position
		return true
	return false

func change_direction() -> void:
	place_room(position)
	steps_since_turn = 0

	var candidates := DIRECTIONS.duplicate()
	candidates.erase(direction)
	candidates.shuffle()

	# Walk the shuffled list for the first in-bounds heading. The old version
	# popped inside a `while` with no empty check, so a walker boxed into a
	# corner popped past the end of the array and tried `position + null`.
	for candidate in candidates:
		if borders.has_point(position + candidate):
			direction = candidate
			return

	# Fully boxed in (only possible in a 1-cell pocket): reverse and let the
	# next step() bail cleanly rather than erroring.
	direction = -direction

func create_room(room_position: Vector2, size: Vector2) -> Dictionary:
	return {position = room_position, size = size}

func place_room(room_position: Vector2) -> void:
	var size := Vector2(
		randi_range(0, randi_range(2, 4) - 1) + randi_range(1, 7),
		randi_range(0, randi_range(2, 4) - 1) + randi_range(1, 7))
	var top_left_corner := (room_position - size / 2).floor()

	rooms.append(create_room(room_position, size))

	for y in size.y:
		for x in size.x:
			var new_step := top_left_corner + Vector2(x, y)
			if borders.has_point(new_step):
				_mark(new_step)

# Returns the room furthest from the spawn point, for exit placement.
func get_end_room() -> Dictionary:
	if rooms.is_empty():
		return create_room(position, Vector2.ONE)

	var starting_position: Vector2 = step_history.front()
	var end_room: Dictionary = rooms.back()

	# Reads `rooms` without mutating it. This used to pop_back(), so calling it
	# twice returned different answers and silently shortened the room list.
	for room in rooms:
		if starting_position.distance_to(room.position) > starting_position.distance_to(end_room.position):
			end_room = room
	return end_room

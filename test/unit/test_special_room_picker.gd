extends GutTest

# SpecialRoomPicker filters the walker's overlapping stamps down to stamps that
# read as discrete rooms. It is all static and all pure, so it can be driven
# with hand-built fixtures -- and it has to be, because the thing it protects
# against (three "rooms" that are really one lumpy space, or an ambush sealed
# around a 2x1 corridor) is invisible until you are standing in it.

const SEP := SpecialRoomPicker.SEPARATION
const MIN := SpecialRoomPicker.MIN_ROOM_SIZE


func _room(pos: Vector2, size: Vector2) -> Dictionary:
	return {position = pos, size = size}


# A lookup where every cell of `rect` is carved.
func _carved(rect: Rect2) -> Dictionary:
	var lookup := {}
	for y in int(rect.size.y):
		for x in int(rect.size.x):
			lookup[rect.position + Vector2(x, y)] = true
	return lookup


func _merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	out.merge(b)
	return out


# --- tile_rect ------------------------------------------------------------

func test_tile_rect_centres_the_stamp_and_floors_the_corner():
	var rect := SpecialRoomPicker.tile_rect(_room(Vector2(10, 10), Vector2(5, 5)))
	assert_eq(rect, Rect2(7, 7, 5, 5))


func test_tile_rect_keeps_the_stamp_size():
	var rect := SpecialRoomPicker.tile_rect(_room(Vector2(3, 9), Vector2(6, 4)))
	assert_eq(rect.size, Vector2(6, 4))


func test_tile_rect_matches_the_cells_the_walker_really_carved():
	# The comment on tile_rect warns that it has to floor identically to
	# place_room or the rect drifts half a tile off the carved cells. This runs
	# a real walk and checks every stamp against the real lookup.
	var borders := Rect2(1, 1, 60, 40)
	var walker := WalkerRoom.new(Vector2(20, 20), borders)
	walker.walk(600)
	var lookup := walker.get_floor_lookup()

	for room in walker.rooms:
		var rect: Rect2 = SpecialRoomPicker.tile_rect(room)
		for y in int(rect.size.y):
			for x in int(rect.size.x):
				var cell: Vector2 = rect.position + Vector2(x, y)
				if borders.has_point(cell):
					assert_true(lookup.has(cell),
						"tile_rect claims %s for room %s but it was never carved"
							% [cell, room.position])


# --- is_fully_carved ------------------------------------------------------

func test_a_fully_carved_rect_is_accepted():
	var rect := Rect2(0, 0, 6, 6)
	assert_true(SpecialRoomPicker.is_fully_carved(rect, _carved(rect)))


func test_an_empty_lookup_rejects_everything():
	assert_false(SpecialRoomPicker.is_fully_carved(Rect2(0, 0, 6, 6), {}))


func test_a_rect_missing_its_centre_is_rejected():
	var rect := Rect2(0, 0, 7, 7)
	var lookup := _carved(rect)
	lookup.erase(rect.get_center().floor())
	assert_false(SpecialRoomPicker.is_fully_carved(rect, lookup))


func test_a_rect_missing_any_corner_is_rejected():
	var rect := Rect2(0, 0, 6, 6)
	var far := rect.position + rect.size - Vector2.ONE
	var corners := [rect.position, Vector2(far.x, rect.position.y),
		Vector2(rect.position.x, far.y), far]

	for corner in corners:
		var lookup := _carved(rect)
		lookup.erase(corner)
		assert_false(SpecialRoomPicker.is_fully_carved(rect, lookup),
			"a rect clipped at corner %s was accepted as whole" % corner)


func test_a_single_cell_rect_needs_only_its_own_cell():
	assert_true(SpecialRoomPicker.is_fully_carved(Rect2(4, 4, 1, 1), {Vector2(4, 4): true}))


# --- select: filtering ----------------------------------------------------

func test_rooms_below_the_minimum_size_are_never_chosen():
	var small := _room(Vector2(20, 20), Vector2(MIN - 1, MIN + 3))
	var lookup := _carved(SpecialRoomPicker.tile_rect(small))
	assert_eq(SpecialRoomPicker.select([small], [], 3, lookup).size(), 0,
		"a room too narrow to fight in was offered as a special room")


func test_a_room_at_exactly_the_minimum_size_qualifies():
	var room := _room(Vector2(20, 20), Vector2(MIN, MIN))
	var lookup := _carved(SpecialRoomPicker.tile_rect(room))
	assert_eq(SpecialRoomPicker.select([room], [], 3, lookup).size(), 1)


func test_a_clipped_room_is_never_chosen():
	# Carve everything except one corner, as the borders would.
	var room := _room(Vector2(20, 20), Vector2(8, 8))
	var rect := SpecialRoomPicker.tile_rect(room)
	var lookup := _carved(rect)
	lookup.erase(rect.position)
	assert_eq(SpecialRoomPicker.select([room], [], 3, lookup).size(), 0,
		"a room half-buried in rock was offered as a special room")


func test_a_room_overlapping_an_excluded_rect_is_never_chosen():
	var room := _room(Vector2(20, 20), Vector2(8, 8))
	var lookup := _carved(SpecialRoomPicker.tile_rect(room))
	var excluded := [SpecialRoomPicker.tile_rect(room)]
	assert_eq(SpecialRoomPicker.select([room], excluded, 3, lookup).size(), 0)


func test_a_room_within_the_separation_of_an_excluded_rect_is_never_chosen():
	# Adjacent but not overlapping: still too close to read as its own space.
	var room := _room(Vector2(20, 20), Vector2(8, 8))
	var rect := SpecialRoomPicker.tile_rect(room)
	var lookup := _carved(rect)
	var neighbour := Rect2(rect.position + Vector2(rect.size.x + 1, 0), Vector2(4, 4))
	assert_eq(SpecialRoomPicker.select([room], [neighbour], 3, lookup).size(), 0,
		"a room was chosen right up against an excluded area")


func test_a_room_clear_of_the_separation_is_chosen():
	var room := _room(Vector2(20, 20), Vector2(8, 8))
	var rect := SpecialRoomPicker.tile_rect(room)
	var lookup := _carved(rect)
	var far_away := Rect2(rect.position + Vector2(rect.size.x + SEP + 5, 0), Vector2(4, 4))
	assert_eq(SpecialRoomPicker.select([room], [far_away], 3, lookup).size(), 1)


func test_the_min_size_override_is_honoured():
	var room := _room(Vector2(20, 20), Vector2(3, 3))
	var lookup := _carved(SpecialRoomPicker.tile_rect(room))
	assert_eq(SpecialRoomPicker.select([room], [], 3, lookup, 3).size(), 1,
		"the min_size override was ignored")


# --- select: choosing -----------------------------------------------------

func _spread_rooms(n: int, gap: int) -> Array:
	var rooms: Array = []
	for i in n:
		rooms.append(_room(Vector2(20 + i * gap, 20), Vector2(8, 8)))
	return rooms


func _lookup_for(rooms: Array) -> Dictionary:
	var lookup := {}
	for room in rooms:
		lookup = _merge(lookup, _carved(SpecialRoomPicker.tile_rect(room)))
	return lookup


func test_no_more_than_the_requested_count_is_returned():
	var rooms := _spread_rooms(6, 40)
	assert_eq(SpecialRoomPicker.select(rooms, [], 3, _lookup_for(rooms)).size(), 3)


func test_asking_for_zero_returns_nothing():
	var rooms := _spread_rooms(4, 40)
	assert_eq(SpecialRoomPicker.select(rooms, [], 0, _lookup_for(rooms)).size(), 0)


func test_fewer_are_returned_when_the_walk_has_no_more_to_give():
	# A normal outcome, not a failure -- callers must cope with a short list.
	var rooms := _spread_rooms(2, 40)
	assert_eq(SpecialRoomPicker.select(rooms, [], 5, _lookup_for(rooms)).size(), 2)


func test_an_empty_room_list_returns_nothing():
	assert_eq(SpecialRoomPicker.select([], [], 3, {}).size(), 0)


func test_chosen_rooms_are_all_from_the_input():
	var rooms := _spread_rooms(5, 40)
	var chosen := SpecialRoomPicker.select(rooms, [], 3, _lookup_for(rooms))
	for room in chosen:
		assert_has(rooms, room, "select() invented a room that was not offered")


func test_chosen_rooms_are_never_the_same_room_twice():
	var rooms := _spread_rooms(5, 40)
	var chosen := SpecialRoomPicker.select(rooms, [], 3, _lookup_for(rooms))
	var seen := {}
	for room in chosen:
		var key: Vector2 = room.position
		assert_false(seen.has(key), "the same room was chosen twice")
		seen[key] = true


func test_chosen_rooms_are_kept_apart_from_each_other():
	# The whole point of the filter: two stamps that merely fail to overlap
	# still read as one lumpy space.
	var rooms := _spread_rooms(8, 40)
	var chosen := SpecialRoomPicker.select(rooms, [], 4, _lookup_for(rooms))
	for i in chosen.size():
		for j in chosen.size():
			if i == j:
				continue
			var padded: Rect2 = SpecialRoomPicker.tile_rect(chosen[i]).grow(SEP)
			assert_false(padded.intersects(SpecialRoomPicker.tile_rect(chosen[j])),
				"chosen rooms %s and %s are closer than the separation"
					% [chosen[i].position, chosen[j].position])


func test_a_cluster_of_overlapping_stamps_yields_one_room():
	# Six stamps all on top of each other is one space, however many entries the
	# walker recorded for it.
	var rooms: Array = []
	for i in 6:
		rooms.append(_room(Vector2(20 + i, 20), Vector2(8, 8)))
	assert_eq(SpecialRoomPicker.select(rooms, [], 4, _lookup_for(rooms)).size(), 1,
		"a pile of overlapping stamps was sold as several rooms")


func test_selection_does_not_mutate_the_room_list():
	var rooms := _spread_rooms(5, 40)
	var before: int = rooms.size()
	SpecialRoomPicker.select(rooms, [], 3, _lookup_for(rooms))
	assert_eq(rooms.size(), before, "select() consumed the walker's room list")


func test_selection_does_not_mutate_the_excluded_list():
	var rooms := _spread_rooms(3, 40)
	var excluded := [Rect2(500, 500, 4, 4)]
	SpecialRoomPicker.select(rooms, excluded, 3, _lookup_for(rooms))
	assert_eq(excluded.size(), 1, "select() modified the excluded list")


func test_selection_survives_a_real_walk():
	# The integration case: whatever the walker produces, select() must return a
	# well-formed, well-separated list and must not error.
	var borders := Rect2(1, 1, 80, 60)
	var walker := WalkerRoom.new(Vector2(20, 20), borders)
	walker.walk(1200)

	var chosen := SpecialRoomPicker.select(
		walker.rooms, [], 3, walker.get_floor_lookup())

	assert_true(chosen.size() <= 3, "select() returned more rooms than asked for")
	for room in chosen:
		assert_true(room.size.x >= MIN and room.size.y >= MIN,
			"a room below the minimum size came out of a real walk")
		assert_true(SpecialRoomPicker.is_fully_carved(
			SpecialRoomPicker.tile_rect(room), walker.get_floor_lookup()),
			"a clipped room came out of a real walk")

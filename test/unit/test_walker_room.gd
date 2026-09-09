extends GutTest

# WalkerRoom is the drunkard's-walk level generator. It is pure -- no scene
# tree, no rendering, no input -- which makes it both the most testable code in
# the project and the place where a silent break is most expensive: a bad walk
# means a hole in the map or an exit embedded in rock, and neither announces
# itself while playing.
#
# NOTE: _init() asserts that the start is inside borders. That is deliberately
# not tested -- a failed assert halts the whole run and GUT cannot trap it.

const BORDERS := Rect2(1, 1, 60, 40)
const START := Vector2(5, 5)
const STEPS := 800


func _walker(borders: Rect2 = BORDERS, start: Vector2 = START) -> WalkerRoom:
	return WalkerRoom.new(start, borders)


# --- the border invariant -------------------------------------------------
#
# Everything downstream trusts this. main_room clears the authored tile block
# and re-lays walls around whatever the walker did NOT carve, so a single cell
# outside borders is a hole the player can walk out through.

func test_every_carved_cell_is_inside_borders():
	var cells := _walker().walk(STEPS)
	for cell in cells:
		assert_true(BORDERS.has_point(cell),
			"carved cell %s escaped borders %s" % [cell, BORDERS])


func test_cells_stay_in_bounds_in_a_one_wide_corridor():
	var corridor := Rect2(0, 0, 1, 30)
	var cells := WalkerRoom.new(Vector2(0, 0), corridor).walk(400)
	for cell in cells:
		assert_true(corridor.has_point(cell),
			"cell %s escaped corridor %s" % [cell, corridor])


func test_cells_stay_in_bounds_when_starting_on_the_border_edge():
	var cells := _walker(BORDERS, BORDERS.position).walk(STEPS)
	for cell in cells:
		assert_true(BORDERS.has_point(cell), "cell %s escaped from an edge start" % cell)


func test_carved_area_never_exceeds_the_border_area():
	var cells := _walker().walk(STEPS)
	assert_lt(cells.size(), int(BORDERS.size.x * BORDERS.size.y) + 1,
		"carved more cells than the playfield can hold")


# --- the carved set -------------------------------------------------------

func test_the_start_cell_is_carved():
	var walker := _walker()
	var cells := walker.walk(STEPS)
	assert_has(cells, START, "the walker's own start was never marked as floor")


func test_the_player_spawn_is_the_start_cell():
	# main_room does `map.pop_front() * TILE_SIZE` to place the player, so the
	# first entry has to be somewhere the player can legally stand.
	var walker := _walker()
	var cells := walker.walk(STEPS)
	assert_eq(cells.front(), START, "player would not spawn on the walker's start")


func test_no_cell_is_recorded_twice():
	var cells := _walker().walk(STEPS)
	var seen := {}
	for cell in cells:
		assert_false(seen.has(cell), "cell %s recorded more than once" % cell)
		seen[cell] = true


func test_lookup_and_history_describe_the_same_cells():
	# generate_level() tests membership against the lookup but spawns from the
	# array. If they ever disagree, enemies spawn inside walls.
	var walker := _walker()
	var cells := walker.walk(STEPS)
	var lookup := walker.get_floor_lookup()

	assert_eq(lookup.size(), cells.size(), "lookup and history are different sizes")
	for cell in cells:
		assert_true(lookup.has(cell), "cell %s is in the history but not the lookup" % cell)


func test_walking_zero_steps_still_stamps_the_starting_room():
	var cells := _walker().walk(0)
	assert_gt(cells.size(), 0, "a zero-step walk produced no floor at all")


# --- exit placement -------------------------------------------------------

func test_end_room_sits_on_a_carved_cell():
	# main_room puts the exit at get_end_room().position. If that is not floor,
	# the exit is buried in rock and the floor cannot be finished.
	var walker := _walker()
	walker.walk(STEPS)
	var lookup := walker.get_floor_lookup()
	assert_true(lookup.has(walker.get_end_room().position),
		"the exit would be placed on a cell that was never carved")


func test_end_room_is_stable_across_calls():
	# Regression: this used to pop_back(), so asking twice gave two answers and
	# quietly shortened the room list each time.
	var walker := _walker()
	walker.walk(STEPS)
	assert_eq(walker.get_end_room(), walker.get_end_room(),
		"get_end_room() is not idempotent")


func test_end_room_does_not_consume_the_room_list():
	var walker := _walker()
	walker.walk(STEPS)
	var before: int = walker.rooms.size()
	walker.get_end_room()
	walker.get_end_room()
	assert_eq(walker.rooms.size(), before, "get_end_room() mutated the room list")


func test_end_room_is_the_furthest_room_from_the_start():
	var walker := _walker()
	var cells := walker.walk(STEPS)
	var start: Vector2 = cells.front()
	var end_room: Dictionary = walker.get_end_room()
	var furthest: float = start.distance_to(end_room.position)

	for room in walker.rooms:
		assert_true(start.distance_to(room.position) <= furthest,
			"room %s is further from the start than the chosen end room" % room.position)


func test_end_room_before_walking_falls_back_to_the_current_position():
	var walker := _walker()
	var room := walker.get_end_room()
	assert_eq(room.position, START, "empty-room fallback did not use the walker position")


func test_end_room_is_one_of_the_rooms_that_were_placed():
	var walker := _walker()
	walker.walk(STEPS)
	assert_has(walker.rooms, walker.get_end_room(),
		"the end room is not a room the walker actually placed")


# --- stepping -------------------------------------------------------------

func test_step_moves_the_walker_when_the_target_is_in_bounds():
	var walker := _walker()
	walker.direction = Vector2.RIGHT
	assert_true(walker.step(), "step() refused a legal move")
	assert_eq(walker.position, START + Vector2.RIGHT)


func test_step_refuses_to_leave_the_borders():
	var box := Rect2(1, 1, 5, 5)
	var walker := WalkerRoom.new(Vector2(5, 5), box)
	walker.direction = Vector2.RIGHT

	assert_false(walker.step(), "step() walked through the border")
	assert_eq(walker.position, Vector2(5, 5), "a refused step still moved the walker")


func test_step_counts_toward_the_next_turn():
	var walker := _walker()
	walker.direction = Vector2.RIGHT
	walker.step()
	assert_eq(walker.steps_since_turn, 1)


func test_a_refused_step_does_not_count_toward_the_next_turn():
	var box := Rect2(1, 1, 5, 5)
	var walker := WalkerRoom.new(Vector2(5, 5), box)
	walker.direction = Vector2.RIGHT
	walker.step()
	assert_eq(walker.steps_since_turn, 0, "a blocked step advanced the turn counter")


# --- turning --------------------------------------------------------------

func test_change_direction_always_picks_a_new_heading():
	var walker := _walker()
	var before: Vector2 = walker.direction
	walker.change_direction()
	assert_ne(walker.direction, before, "the walker turned onto its own heading")


func test_change_direction_resets_the_turn_counter():
	var walker := _walker()
	walker.direction = Vector2.RIGHT
	walker.step()
	walker.change_direction()
	assert_eq(walker.steps_since_turn, 0)


func test_change_direction_survives_a_single_cell_pocket():
	# Regression: the old version popped from the candidate list inside a while
	# loop with no empty check, so a boxed-in walker ran off the end of the
	# array and evaluated `position + null`.
	var pocket := Rect2(0, 0, 1, 1)
	var walker := WalkerRoom.new(Vector2.ZERO, pocket)
	walker.change_direction()
	assert_eq(walker.position, Vector2.ZERO, "a boxed-in walker moved")


func test_walking_inside_a_single_cell_pocket_terminates():
	var pocket := Rect2(0, 0, 1, 1)
	var cells := WalkerRoom.new(Vector2.ZERO, pocket).walk(200)
	assert_eq(cells, [Vector2.ZERO] as Array[Vector2],
		"a one-cell pocket carved something other than its one cell")


# --- reproducibility ------------------------------------------------------

func test_the_same_seed_produces_the_same_map():
	# Level generation is seeded by randomize() at load. Determinism under a
	# fixed seed is what makes a bad level reproducible when one is reported.
	seed(20260731)
	var first := _walker().walk(STEPS)
	seed(20260731)
	var second := _walker().walk(STEPS)
	assert_eq(first, second, "the same seed produced two different maps")


func test_different_seeds_produce_different_maps():
	seed(1)
	var first := _walker().walk(STEPS)
	seed(999999)
	var second := _walker().walk(STEPS)
	assert_ne(first, second, "the generator ignored the seed")


# --- rooms ----------------------------------------------------------------

func test_rooms_accumulate_over_a_walk():
	var walker := _walker()
	walker.walk(STEPS)
	assert_gt(walker.rooms.size(), 1, "a long walk placed at most one room")


func test_every_placed_room_records_a_position_and_a_size():
	var walker := _walker()
	walker.walk(STEPS)
	for room in walker.rooms:
		assert_true(room.has("position"), "a room is missing its position")
		assert_true(room.has("size"), "a room is missing its size")

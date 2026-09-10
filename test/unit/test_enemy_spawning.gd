extends GutTest

# Spawn counts, for both level types.
#
# These take a PackedScene argument, so the fixtures hand them a bare packed
# Node2D instead of a real enemy. That keeps the tests counting spawns rather
# than booting enemy AI that expects a Player sibling -- and it means a count
# bug shows up as a number, not as a room that feels slightly off.
#
# The bug this exists for: every caller of spawn_wave() used to instantiate one
# enemy outside the loop and add_child() it `count` times, so a wave advertised
# as 12 delivered 1 and logged "node already has a parent" eleven times.

const MainRoom := preload("res://Levels/level_generator_script/main_room.gd")

var dummy_scene: PackedScene


func before_all():
	# A minimal scene with nothing in it but a Node2D.
	var root := Node2D.new()
	dummy_scene = PackedScene.new()
	dummy_scene.pack(root)
	root.free()


func before_each():
	PlayerData.reset_run()


func after_each():
	PlayerData.reset_run()


# --- main_room: Culling Order --------------------------------------------

func _level() -> Node2D:
	var room: Node2D = autofree(MainRoom.new())
	# spawn_enemies places each spawn on a random carved cell.
	room.map = [Vector2(5, 5), Vector2(6, 5), Vector2(7, 5)]
	return room


func test_a_full_wave_spawns_every_enemy():
	var room := _level()
	room.spawn_enemies(dummy_scene, 12)
	assert_eq(room.get_child_count(), 12, "a wave of 12 did not deliver 12 enemies")


func test_culling_order_thins_a_wave():
	PlayerData.cull_active = true
	var room := _level()
	room.spawn_enemies(dummy_scene, 10)
	assert_eq(room.get_child_count(), 7,
		"Culling Order did not leave 70%% of the wave standing")


func test_culling_order_does_nothing_when_not_bought():
	PlayerData.cull_active = false
	var room := _level()
	room.spawn_enemies(dummy_scene, 10)
	assert_eq(room.get_child_count(), 10)


func test_culling_a_single_enemy_wave_still_leaves_one():
	# 1 * 0.7 rounds back up to 1, so the smallest wave survives intact. Note
	# this passes with or without the maxi(1, ...) guard in spawn_enemies --
	# see test_culling_rounds_to_the_nearest_enemy for why that guard is dead
	# code at the counts the game actually uses.
	PlayerData.cull_active = true
	var room := _level()
	room.spawn_enemies(dummy_scene, 1)
	assert_eq(room.get_child_count(), 1, "Culling Order deleted a whole small wave")


func test_culling_rounds_to_the_nearest_enemy():
	# The exact contract, so a change to CULL_MULTIPLIER has to be deliberate.
	#
	# Every count here rounds to 1 or more on its own, which is why maxi(1, ...)
	# never binds: the only count it changes is 0, and there it would turn an
	# empty wave into one enemy. No caller passes 0 -- every instance_enemyN()
	# floors its randi_range at 1 -- so the guard is unreachable rather than
	# wrong.
	PlayerData.cull_active = true
	for pair in [[1, 1], [2, 1], [3, 2], [4, 3], [5, 4], [10, 7], [20, 14]]:
		var room := _level()
		room.spawn_enemies(dummy_scene, pair[0])
		assert_eq(room.get_child_count(), pair[1],
			"a wave of %d culled to the wrong size" % pair[0])


func test_culling_leaves_hazards_alone():
	# Sold as thinning the enemies. Quietly halving the spikes as well would
	# make it strictly better than it reads.
	PlayerData.cull_active = true
	var room := _level()
	room.spawn_enemies(dummy_scene, 10, false)
	assert_eq(room.get_child_count(), 10,
		"Culling Order thinned the spikes as well as the enemies")


func test_spawning_zero_enemies_spawns_nothing():
	var room := _level()
	room.spawn_enemies(dummy_scene, 0)
	assert_eq(room.get_child_count(), 0)


func test_every_spawn_lands_on_a_carved_cell():
	var room := _level()
	var legal := [Vector2(5, 5) * room.TILE_SIZE, Vector2(6, 5) * room.TILE_SIZE,
		Vector2(7, 5) * room.TILE_SIZE]
	room.spawn_enemies(dummy_scene, 20)
	for child in room.get_children():
		assert_has(legal, (child as Node2D).position,
			"an enemy spawned somewhere that was never carved")


# --- main_room: the ambush roster ----------------------------------------

func _room_with_enemy_scenes() -> Node2D:
	var room := _level()
	# @onready preloads are unassigned on a detached node, so the roster gets
	# distinguishable stand-ins.
	room.enemy1_scene = dummy_scene
	room.enemy2_scene = dummy_scene
	room.enemy3_scene = dummy_scene
	room.enemy4_scene = dummy_scene
	return room


func test_the_ambush_roster_always_returns_something():
	for levels in [1, 3, 6, 12, 20]:
		PlayerData.levels = levels
		assert_not_null(_room_with_enemy_scenes().ambush_enemy_scene(),
			"no ambush enemy available at level %d" % levels)


func test_the_early_ambush_roster_is_only_the_first_enemy():
	PlayerData.levels = 1
	var room := _room_with_enemy_scenes()
	room.enemy1_scene = dummy_scene
	# Distinct instances so identity means something.
	var other := PackedScene.new()
	room.enemy2_scene = other
	room.enemy3_scene = other
	room.enemy4_scene = other
	for i in 20:
		assert_eq(room.ambush_enemy_scene(), dummy_scene,
			"a level 1 ambush drew an enemy the floor cannot spawn yet")


# --- arena levels: wave spawning -----------------------------------------

func _arena() -> Node2D:
	return autofree(ArenaLevel.new())


func _markers(count: int, parent: Node) -> Array:
	var markers: Array = []
	for i in count:
		var marker := Marker2D.new()
		marker.name = "enemy_spawn_%d" % i
		marker.position = Vector2(i * 32, 0)
		parent.add_child(marker)
		markers.append(marker)
	return markers


func test_a_wave_spawns_the_number_it_says():
	var arena := _arena()
	var markers := _markers(4, arena)
	arena.spawn_wave(dummy_scene, 12, markers)
	assert_eq(arena.get_child_count() - markers.size(), 12,
		"a wave of 12 delivered a different number")


func test_a_wave_stops_at_the_live_enemy_cap():
	var arena := _arena()
	arena.max_live_enemies = 5
	var markers := _markers(4, arena)
	arena.spawn_wave(dummy_scene, 50, markers)
	assert_eq(arena.get_child_count() - markers.size(), 5,
		"the wave ran past the live-enemy cap")


func test_the_cap_counts_across_waves():
	# These rooms spawn forever and nothing despawns.
	var arena := _arena()
	arena.max_live_enemies = 10
	var markers := _markers(4, arena)
	for i in 5:
		arena.spawn_wave(dummy_scene, 4, markers)
	assert_eq(arena.get_child_count() - markers.size(), 10)


func test_a_wave_with_no_markers_spawns_nothing():
	var arena := _arena()
	arena.spawn_wave(dummy_scene, 8, [])
	assert_eq(arena.get_child_count(), 0, "enemies spawned with nowhere to put them")


func test_every_spawn_lands_on_a_marker():
	var arena := _arena()
	var markers := _markers(4, arena)
	var legal: Array = []
	for marker in markers:
		legal.append((marker as Node2D).position)

	arena.spawn_wave(dummy_scene, 12, markers)
	for child in arena.get_children():
		if child is Marker2D:
			continue
		assert_has(legal, (child as Node2D).position,
			"an enemy spawned off-marker")


func test_killing_enemies_frees_room_under_the_cap():
	var arena := _arena()
	arena.max_live_enemies = 3
	var markers := _markers(2, arena)
	arena.spawn_wave(dummy_scene, 3, markers)

	for child in arena.get_children():
		if not (child is Marker2D):
			child.free()
			break

	arena.spawn_wave(dummy_scene, 1, markers)
	assert_eq(arena._live_enemies, 3, "a dead enemy never freed its slot")


# --- arena levels: marker collection -------------------------------------

func test_markers_are_collected_by_name_prefix():
	var arena := _arena()
	_markers(5, arena)
	assert_eq(arena.collect_markers("enemy_spawn").size(), 5)


func test_collection_ignores_other_prefixes():
	var arena := _arena()
	_markers(3, arena)
	var spike := Marker2D.new()
	spike.name = "spikes_0"
	arena.add_child(spike)
	assert_eq(arena.collect_markers("enemy_spawn").size(), 3,
		"a marker with a different prefix was collected")


func test_collection_ignores_timers_sharing_the_prefix():
	# The Marker2D type check is what keeps `enemy_spawn` (a Timer) out.
	var arena := _arena()
	_markers(3, arena)
	var timer := Timer.new()
	timer.name = "enemy_spawn"
	arena.add_child(timer)
	assert_eq(arena.collect_markers("enemy_spawn").size(), 3,
		"a Timer was collected as a spawn marker")


func test_collecting_an_unknown_prefix_returns_nothing():
	var arena := _arena()
	_markers(3, arena)
	assert_eq(arena.collect_markers("nothing_named_this").size(), 0)


# --- arena levels: spike placement ---------------------------------------

func _arena_with_spikes() -> Node2D:
	var arena := _arena()
	arena.silverspikes_scene = dummy_scene
	arena.redspikes_scene = dummy_scene
	return arena


func test_placing_a_spike_consumes_exactly_one_marker():
	# Regression: the old version called pop_at(i), which already removes, and
	# then remove_at(i) -- silently deleting a second, unrelated marker.
	var arena := _arena_with_spikes()
	var markers := _markers(10, arena).duplicate()
	arena.spawn_random_spike(markers, 0)
	assert_eq(markers.size(), 9, "placing one spike consumed the wrong number of markers")


func test_the_reserve_is_respected():
	var arena := _arena_with_spikes()
	var markers := _markers(10, arena).duplicate()
	for i in 20:
		arena.spawn_random_spike(markers, 4)
	assert_eq(markers.size(), 4, "the reserved markers were used up")


func test_nothing_is_placed_when_only_the_reserve_is_left():
	var arena := _arena_with_spikes()
	var markers := _markers(3, arena).duplicate()
	var before: int = arena.get_child_count()
	arena.spawn_random_spike(markers, 3)
	assert_eq(arena.get_child_count(), before, "a spike was placed out of the reserve")


func test_spikes_can_be_drawn_from_anywhere_in_the_list():
	# Regression: the old index range was randi_range(0, size - reserve), so with
	# a reserve held back the markers at the end of the list were unreachable
	# rather than merely reserved -- spikes only ever appeared at the front.
	#
	# One draw per trial from a fresh list, recording which index was taken. The
	# buggy range can never exceed 5 here; the correct one reaches 11 within a
	# few trials, so 60 makes a false failure vanishingly unlikely.
	var arena := _arena_with_spikes()
	var highest := -1

	for trial in 60:
		var markers := _markers(12, arena).duplicate()
		var before := markers.duplicate()
		arena.spawn_random_spike(markers, 6)
		for i in before.size():
			if not markers.has(before[i]):
				highest = maxi(highest, i)
				break

	assert_gt(highest, 7,
		"markers past index %d were never drawn; the reserve is unreachable, not held back"
			% highest)


# --- the floor enemy budget ----------------------------------------------
#
# The per-pass counts are open-ended in `levels`: at level 18 the passes ask for
# up to 90 + 72 + 2x36 + 2x54 CharacterBody2Ds, every one running move_and_slide
# from _process. ArenaLevel has had max_live_enemies since the wave-spawn fix;
# the procedural floors never got the same treatment.

func test_a_floor_stops_at_the_enemy_budget():
	var room := _level()
	room.spawn_enemies(dummy_scene, MainRoom.MAX_FLOOR_ENEMIES + 50)
	assert_eq(room.get_child_count(), MainRoom.MAX_FLOOR_ENEMIES,
		"a single pass spawned past the floor budget")


func test_the_budget_is_spent_across_passes_not_per_pass():
	var room := _level()
	for i in 5:
		room.spawn_enemies(dummy_scene, 50)
	assert_eq(room.get_child_count(), MainRoom.MAX_FLOOR_ENEMIES,
		"each pass got its own budget instead of sharing the floor's")


func test_hazards_are_not_charged_against_the_enemy_budget():
	# The spike passes come through with cullable false. A floor that quietly
	# stopped laying hazards once the enemies filled up would be a difficulty
	# cliff with nothing on screen to explain it.
	var room := _level()
	room.spawn_enemies(dummy_scene, MainRoom.MAX_FLOOR_ENEMIES)
	room.spawn_enemies(dummy_scene, 12, false)
	assert_eq(room.get_child_count(), MainRoom.MAX_FLOOR_ENEMIES + 12,
		"hazards were refused because the enemy budget was spent")


func test_an_ordinary_wave_is_untouched_by_the_budget():
	var room := _level()
	room.spawn_enemies(dummy_scene, 12)
	assert_eq(room.get_child_count(), 12,
		"the budget clipped a wave nowhere near it")


# --- keeping roamers out of the special rooms -----------------------------
#
# Roaming enemies are spawned after the special rooms are built, from the whole
# carved-cell list. One landing inside an ambush is not registered with it, so it
# does not hold the door shut -- but the player gets sealed in with more than the
# room was built to hold.

func _room_with_reserved_area() -> Node2D:
	var room := _level()
	room.map = []
	# A 6x6 block of carved cells, of which the middle 4x4 is spoken for.
	for y in range(0, 6):
		for x in range(0, 6):
			room.map.append(Vector2(x, y))
	# Typed on the way in: reserved_rects is an Array[Rect2], and assigning an
	# untyped literal to it throws rather than converting.
	var reserved: Array[Rect2] = [Rect2(1, 1, 4, 4)]
	room.reserved_rects = reserved
	return room


func test_roaming_enemies_avoid_a_reserved_room():
	var room := _room_with_reserved_area()
	room.spawn_enemies(dummy_scene, 40)
	for child in room.get_children():
		var cell: Vector2 = (child as Node2D).position / room.TILE_SIZE
		assert_false(room.reserved_rects[0].has_point(cell),
			"a roaming enemy spawned inside a special room at %s" % cell)


func test_hazards_ignore_the_reservation():
	# Spikes inside a treasure cache are part of the risk; they do not follow the
	# player into a sealed room the way an unregistered enemy does.
	var room := _room_with_reserved_area()
	room.spawn_enemies(dummy_scene, 20, false)
	assert_eq(room.get_child_count(), 20, "hazards were refused a placement")


func test_placement_gives_up_rather_than_hanging_when_everything_is_reserved():
	# No carved cell is legal. The pick has to fall back, not spin.
	var room := _level()
	var everything: Array[Rect2] = [Rect2(0, 0, 100, 100)]
	room.reserved_rects = everything
	room.spawn_enemies(dummy_scene, 5)
	assert_eq(room.get_child_count(), 5,
		"spawning stalled or dropped enemies when every cell was reserved")


# --- one tier formula -----------------------------------------------------

func test_the_first_three_floors_are_tier_zero():
	for level in [1, 2, 3]:
		assert_eq(MainRoom.tier(level), 0, "level %d is not in the first tier" % level)


func test_a_tier_is_three_floors_wide():
	assert_eq(MainRoom.tier(4), 1)
	assert_eq(MainRoom.tier(6), 1)
	assert_eq(MainRoom.tier(7), 2)


func test_the_tier_climbs_with_the_run():
	var seen := MainRoom.tier(1)
	for level in range(2, 19):
		var now: int = MainRoom.tier(level)
		assert_true(now >= seen, "the tier went backwards at level %d" % level)
		seen = now
	assert_eq(MainRoom.tier(18), 5, "the last procedural floor is not in the last tier")

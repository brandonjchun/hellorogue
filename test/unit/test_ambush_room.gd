extends GutTest

# AmbushRoom is built entirely in code, so its geometry is only ever as correct
# as the arithmetic in _wall_rects(). A gap in the ring is an ambush the player
# walks straight out of; a wall laid over the interior is one they are standing
# inside when it goes up.

const ROOM_SIZE := Vector2(160, 128)

var room: AmbushRoom


func before_each():
	PlayerData.reset_run()
	room = AmbushRoom.new()
	room.setup(ROOM_SIZE)
	add_child_autofree(room)


func after_each():
	PlayerData.reset_run()


func _interior() -> Rect2:
	return Rect2(-ROOM_SIZE / 2.0, ROOM_SIZE)


# A stand-in for the player. The real check is on node name, so that is all
# this needs to get right.
func _player() -> Node2D:
	var body := Node2D.new()
	body.name = "Player"
	return autofree(body)


func _enemy() -> Node:
	var enemy := Node.new()
	add_child(enemy)
	return enemy


# --- geometry -------------------------------------------------------------

func test_the_ring_has_four_walls():
	assert_eq(room._wall_rects().size(), 4)


func test_no_wall_overlaps_the_interior():
	# The player standing anywhere inside must never be caught inside a wall as
	# it goes up.
	for wall in room._wall_rects():
		assert_false(wall.intersects(_interior()),
			"wall %s was laid over the room interior" % wall)


func test_every_wall_has_positive_area():
	for wall in room._wall_rects():
		assert_gt(wall.size.x, 0.0, "wall %s has no width" % wall)
		assert_gt(wall.size.y, 0.0, "wall %s has no height" % wall)


func test_the_ring_is_closed_on_every_side():
	# A point just outside each edge has to land in some wall. If any of the
	# four misses, that side is an open doorway.
	var half := ROOM_SIZE / 2.0
	var just_outside := {
		"above": Vector2(0, -half.y - 1),
		"below": Vector2(0, half.y + 1),
		"left": Vector2(-half.x - 1, 0),
		"right": Vector2(half.x + 1, 0),
	}
	for side in just_outside:
		var point: Vector2 = just_outside[side]
		var covered := false
		for wall in room._wall_rects():
			if wall.has_point(point):
				covered = true
				break
		assert_true(covered, "the %s side of the ring has a gap at %s" % [side, point])


func test_the_corners_are_covered():
	var half := ROOM_SIZE / 2.0
	var t := AmbushRoom.WALL_THICKNESS
	for corner in [Vector2(-half.x - t / 2.0, -half.y - t / 2.0),
			Vector2(half.x + t / 2.0, -half.y - t / 2.0),
			Vector2(-half.x - t / 2.0, half.y + t / 2.0),
			Vector2(half.x + t / 2.0, half.y + t / 2.0)]:
		var covered := false
		for wall in room._wall_rects():
			if wall.has_point(corner):
				covered = true
				break
		assert_true(covered, "corner %s is not sealed" % corner)


func test_a_tiny_room_still_gets_a_trigger_with_area():
	# TILE_MIN is the floor that stops the inset from producing a zero or
	# negative shape on a room only just wider than the inset.
	var tiny := AmbushRoom.new()
	tiny.setup(Vector2(4, 4))
	add_child_autofree(tiny)

	var shape: RectangleShape2D = tiny._trigger.get_child(0).shape
	assert_gt(shape.size.x, 0.0, "a tiny room produced a zero-width trigger")
	assert_gt(shape.size.y, 0.0, "a tiny room produced a zero-height trigger")
	assert_true(shape.size.x >= AmbushRoom.TILE_MIN)


func test_the_trigger_sits_inside_the_walls():
	var shape: RectangleShape2D = room._trigger.get_child(0).shape
	assert_lt(shape.size.x, ROOM_SIZE.x, "the trigger is not inset from the walls")
	assert_lt(shape.size.y, ROOM_SIZE.y)


# --- wiring ---------------------------------------------------------------

func test_the_barrier_starts_down():
	assert_eq(room._barrier.collision_layer, 0,
		"the room was sealed before the player ever entered")


func test_the_trigger_only_watches_for_the_player():
	assert_eq(room._trigger.collision_mask, AmbushRoom.PLAYER_LAYER)
	assert_eq(room._trigger.collision_layer, 0,
		"the trigger is solid and would block movement")


# --- the trap -------------------------------------------------------------

func test_walking_in_with_enemies_alive_seals_the_room():
	room.register_enemy(_enemy())
	room._on_trigger_body_entered(_player())
	assert_true(room._sealed, "the ambush did not close behind the player")


func test_an_empty_room_stands_down_instead_of_sealing():
	# Everything inside died to a stray shot before the player walked in.
	# Sealing would just be a wall they have to wait out.
	room._on_trigger_body_entered(_player())
	assert_false(room._sealed, "an empty ambush sealed the player in for nothing")
	assert_true(room._spent, "an empty ambush did not stand down")


func test_anything_that_is_not_the_player_is_ignored():
	room.register_enemy(_enemy())
	var wanderer: Node2D = autofree(Node2D.new())
	wanderer.name = "enemy_1"
	room._on_trigger_body_entered(wanderer)
	assert_false(room._sealed, "an enemy triggered the ambush")


func test_killing_everything_opens_the_room():
	var enemy := _enemy()
	room.register_enemy(enemy)
	room._on_trigger_body_entered(_player())
	assert_true(room._sealed)

	enemy.free()
	assert_false(room._sealed, "the room stayed sealed after the last enemy died")


func test_the_room_stays_sealed_until_the_last_enemy_dies():
	var first := _enemy()
	var second := _enemy()
	room.register_enemy(first)
	room.register_enemy(second)
	room._on_trigger_body_entered(_player())

	first.free()
	assert_true(room._sealed, "the room opened with an enemy still alive")

	second.free()
	assert_false(room._sealed)


func test_a_finished_room_cannot_re_arm():
	# Set once the room has done its job, so it cannot trap the player a second
	# time on the way back through.
	var enemy := _enemy()
	room.register_enemy(enemy)
	room._on_trigger_body_entered(_player())
	enemy.free()

	room.register_enemy(_enemy())
	room._on_trigger_body_entered(_player())
	assert_false(room._sealed, "a spent ambush trapped the player again")


func test_re_entering_while_sealed_changes_nothing():
	room.register_enemy(_enemy())
	room._on_trigger_body_entered(_player())
	var live: int = room._live_enemies
	room._on_trigger_body_entered(_player())
	assert_eq(room._live_enemies, live)
	assert_true(room._sealed)


func test_enemies_dying_before_the_player_arrives_leave_nothing_to_seal():
	var enemy := _enemy()
	room.register_enemy(enemy)
	enemy.free()
	room._on_trigger_body_entered(_player())
	assert_false(room._sealed, "the room sealed around no enemies at all")
	assert_true(room._spent)

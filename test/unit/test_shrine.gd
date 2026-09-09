extends GutTest

# The shrine trades health for speed. The rule that matters most is the one it
# refuses to break: walking into scenery must never be the thing that ends a
# run.

const SHRINE_SCENE := preload("res://interactables/scenes/shrine.tscn")

var shrine: Shrine


func before_each():
	PlayerData.reset_run()
	shrine = add_child_autofree(SHRINE_SCENE.instantiate())


func after_each():
	PlayerData.reset_run()


func _player() -> Node2D:
	var body := Node2D.new()
	body.name = "Player"
	return autofree(body)


# --- the trade ------------------------------------------------------------

func test_touching_a_shrine_costs_health():
	PlayerData.health = 20
	shrine._on_body_entered(_player())
	assert_eq(PlayerData.health, 20 - Shrine.HEALTH_COST)


func test_touching_a_shrine_grants_haste_for_this_floor():
	PlayerData.health = 20
	shrine._on_body_entered(_player())
	assert_true(PlayerData.haste_active, "the shrine did not grant its boon")


func test_the_boon_is_not_queued_for_the_next_floor():
	# A shrine is touched mid-floor, so it sets haste_active directly rather
	# than riding the _next flag the shop items use.
	PlayerData.health = 20
	shrine._on_body_entered(_player())
	assert_false(PlayerData.haste_next,
		"the shrine armed the next floor instead of this one")


# --- the refusal ----------------------------------------------------------

func test_a_shrine_will_not_kill_you():
	PlayerData.health = Shrine.HEALTH_COST
	shrine._on_body_entered(_player())
	assert_eq(PlayerData.health, Shrine.HEALTH_COST,
		"the shrine charged a player who could not survive it")
	assert_false(PlayerData.haste_active)


func test_a_shrine_will_not_take_you_to_exactly_zero():
	# The guard is `<=`, so a player on exactly the cost is refused too.
	PlayerData.health = Shrine.HEALTH_COST
	shrine._on_body_entered(_player())
	assert_gt(PlayerData.health, 0, "a shrine reduced the player to zero health")


func test_one_point_above_the_cost_is_allowed():
	PlayerData.health = Shrine.HEALTH_COST + 1
	shrine._on_body_entered(_player())
	assert_eq(PlayerData.health, 1)
	assert_true(PlayerData.haste_active)


func test_a_refused_shrine_is_not_spent():
	# It has to still be there when the player comes back with more health.
	PlayerData.health = Shrine.HEALTH_COST
	shrine._on_body_entered(_player())
	assert_false(shrine._spent, "a shrine that refused the trade marked itself used")

	PlayerData.health = 20
	shrine._on_body_entered(_player())
	assert_true(PlayerData.haste_active, "the shrine would not pay out on a second visit")


# --- one use only ---------------------------------------------------------

func test_a_shrine_only_pays_out_once():
	PlayerData.health = 40
	shrine._on_body_entered(_player())
	var after_first: int = PlayerData.health

	shrine._on_body_entered(_player())
	assert_eq(PlayerData.health, after_first, "a shrine was farmed for repeat boons")


func test_a_spent_shrine_looks_spent():
	PlayerData.health = 40
	shrine._on_body_entered(_player())
	assert_eq(shrine.get_node("Sprite2D").modulate, Shrine.SPENT_MODULATE,
		"a used shrine still looks available from across the room")


func test_anything_that_is_not_the_player_is_ignored():
	PlayerData.health = 40
	var wanderer: Node2D = autofree(Node2D.new())
	wanderer.name = "enemy_1"
	shrine._on_body_entered(wanderer)
	assert_eq(PlayerData.health, 40, "an enemy triggered the shrine")
	assert_false(shrine._spent)


func test_a_player_without_refresh_speed_does_not_break_it():
	# The shrine only calls refresh_speed() if the body has it. A bare stand-in
	# must not error.
	PlayerData.health = 40
	shrine._on_body_entered(_player())
	assert_true(PlayerData.haste_active)

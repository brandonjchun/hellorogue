extends GutTest

# The floor clock and the bank, tested against a bare main_room node.
#
# main_room's methods reach for their timers with `$map_timer` at call time
# rather than through @onready, so a detached node with two correctly named
# Timer children is enough to drive them. _ready() is never run -- it needs the
# whole authored level -- which is exactly why these paths were untested.
#
# What is on trial here is the economy rule the whole shop rests on: seconds
# bought at the shop must not be bankable. If they were, Overclock would refund
# 40s for the 25s it cost and buying it would stop being a decision.

const MainRoom := preload("res://Levels/level_generator_script/main_room.gd")

var room: Node2D
var map_timer: Timer
var warning_timer: Timer


func before_each():
	PlayerData.reset_run()

	# Built as a plain Node2D, put in the tree, and only then given the script.
	#
	# Timers refuse to start outside a tree, so the node has to be in one. But
	# main_room's _ready() wants the whole authored level -- GUI, tilemaps,
	# pause menu, loading screens -- and would half-run against none of it,
	# logging a dozen errors and touching PlayerData on the way. Attaching the
	# script after the ready notification has already fired skips _ready() and
	# the @onready lookups entirely, leaving plain methods on a live node.
	var node := Node2D.new()

	map_timer = Timer.new()
	map_timer.name = "map_timer"
	node.add_child(map_timer)

	warning_timer = Timer.new()
	warning_timer.name = "time_running_out_timer"
	node.add_child(warning_timer)

	add_child_autofree(node)
	node.set_script(MainRoom)
	room = node


func after_each():
	PlayerData.reset_run()


# Puts a known number of seconds on the clock.
func _clock(seconds: float) -> void:
	map_timer.start(seconds)


# --- banking --------------------------------------------------------------

func test_leftover_seconds_are_banked():
	_clock(30.0)
	room.bank_floor_time()
	assert_almost_eq(PlayerData.banked_time, 30.0, 0.5)


func test_banking_adds_to_what_was_already_there():
	PlayerData.banked_time = 20.0
	_clock(30.0)
	room.bank_floor_time()
	assert_almost_eq(PlayerData.banked_time, 50.0, 0.5)


func test_the_bank_is_capped():
	PlayerData.banked_time = 100.0
	PlayerData.bank_cap = 120.0
	_clock(60.0)
	room.bank_floor_time()
	assert_eq(PlayerData.banked_time, 120.0, "the bank overflowed its cap")


func test_a_raised_cap_lets_more_through():
	# What Vault Expansion actually buys.
	PlayerData.banked_time = 100.0
	PlayerData.bank_cap = 180.0
	_clock(60.0)
	room.bank_floor_time()
	assert_almost_eq(PlayerData.banked_time, 160.0, 0.5)


func test_banking_only_happens_once_per_floor():
	# _process calls this every frame once the exit is reached.
	_clock(30.0)
	room.bank_floor_time()
	var after_first: float = PlayerData.banked_time

	for i in 10:
		room.bank_floor_time()
	assert_eq(PlayerData.banked_time, after_first,
		"the clock was banked repeatedly while standing on the exit")


func test_an_expired_clock_banks_nothing():
	map_timer.stop()
	room.bank_floor_time()
	assert_eq(PlayerData.banked_time, 0.0)


func test_the_bank_never_goes_negative():
	# floor_bonus_time larger than what is left on the clock.
	PlayerData.floor_bonus_time = 100.0
	_clock(10.0)
	room.bank_floor_time()
	assert_eq(PlayerData.banked_time, 0.0,
		"a floor that ran into its bonus time charged the player for it")


# --- bought seconds are not currency -------------------------------------

func test_bought_seconds_are_not_banked():
	# The floor ran 60s of which 40 were Overclock's. Only the 20 earned count.
	PlayerData.floor_bonus_time = 40.0
	_clock(60.0)
	room.bank_floor_time()
	assert_almost_eq(PlayerData.banked_time, 20.0, 0.5,
		"Overclock's seconds were banked, so it refunds more than it costs")


func test_overclock_cannot_turn_a_profit():
	# The whole rule in one test: buy Overclock, run the floor without touching
	# the extra time, and the bank must not come out ahead of the 25s it cost.
	var cost := 25.0
	var granted := ShopMenu.OVERCLOCK_SECONDS

	PlayerData.banked_time = 100.0 - cost
	PlayerData.floor_bonus_time = granted
	_clock(granted)

	room.bank_floor_time()
	assert_true(PlayerData.banked_time <= 100.0 - cost,
		"buying Overclock left the player richer than not buying it")


func test_a_floor_with_no_bonus_banks_everything_left():
	PlayerData.floor_bonus_time = 0.0
	_clock(45.0)
	room.bank_floor_time()
	assert_almost_eq(PlayerData.banked_time, 45.0, 0.5)


# --- the clock ------------------------------------------------------------

func test_starting_the_clock_starts_both_timers():
	room.start_floor_clock(60.0)
	assert_almost_eq(map_timer.time_left, 60.0, 0.5)
	assert_gt(warning_timer.time_left, 0.0, "the warning timer was never started")


func test_the_warning_lands_ten_seconds_before_the_end():
	room.start_floor_clock(60.0)
	assert_almost_eq(warning_timer.time_left, 50.0, 0.5)


func test_the_warning_never_schedules_in_the_past():
	# A short clock -- a 60s Second Wind refill, say -- gives duration - 10 as a
	# negative number, and maxf floors it at 1s.
	#
	# The distinctive wait_time matters: Timer.start() treats a NEGATIVE argument
	# as "reuse my wait_time", so without it a missing floor would quietly start
	# a 1s default timer and look correct. Here that failure reads as 7.0.
	warning_timer.wait_time = 7.0
	room.start_floor_clock(5.0)
	assert_almost_eq(warning_timer.time_left, 1.0, 0.1,
		"the warning fell back to the timer's own wait_time instead of the 1s floor")


func test_a_very_short_clock_still_arms_the_warning():
	warning_timer.wait_time = 7.0
	room.start_floor_clock(0.5)
	assert_almost_eq(warning_timer.time_left, 1.0, 0.1)


# --- second wind ----------------------------------------------------------

func test_second_wind_absorbs_a_clock_that_ran_out():
	PlayerData.second_wind = true
	room._on_timer_timeout()

	assert_false(PlayerData.toggle_loading_screen,
		"the run ended despite holding Second Wind")
	assert_eq(PlayerData.levels, 1, "the level counter should not have moved")
	assert_almost_eq(map_timer.time_left, PlayerData.SECOND_WIND_SECONDS, 0.5,
		"Second Wind did not put time back on the clock")


func test_second_wind_is_spent_when_it_fires():
	PlayerData.second_wind = true
	room._on_timer_timeout()
	assert_false(PlayerData.second_wind, "Second Wind survived being used")


func test_second_wind_only_works_once():
	PlayerData.second_wind = true
	room._on_timer_timeout()
	room._on_timer_timeout()
	assert_true(PlayerData.toggle_loading_screen,
		"a spent Second Wind absorbed a second expiry")


func test_second_wind_seconds_cannot_be_banked():
	# Surviving on the refill should not also pay out.
	PlayerData.second_wind = true
	room._on_timer_timeout()

	room.bank_floor_time()
	assert_eq(PlayerData.banked_time, 0.0,
		"the player banked the seconds Second Wind gave them")


func test_second_wind_stacks_onto_existing_bonus_time():
	PlayerData.second_wind = true
	PlayerData.floor_bonus_time = 40.0
	room._on_timer_timeout()
	assert_eq(PlayerData.floor_bonus_time, 40.0 + PlayerData.SECOND_WIND_SECONDS)


func test_without_second_wind_the_clock_ends_the_run():
	PlayerData.levels = 12
	room._on_timer_timeout()

	assert_true(PlayerData.toggle_loading_screen, "the run did not end")
	assert_eq(PlayerData.levels, 1, "the run did not restart from the first floor")
	assert_false(PlayerData.reached_exit)

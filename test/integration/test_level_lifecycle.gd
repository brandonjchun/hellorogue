extends GutTest

# The layer the unit suite deliberately cannot reach.
#
# Every test under test/unit/ works on a detached node or a pure function --
# test_floor_clock.gd goes as far as attaching main_room.gd to a bare Node2D
# *after* the ready notification, specifically so _ready() never runs. That is
# the right call for testing arithmetic, but it means the level lifecycle had no
# coverage at all: what _ready() puts back, what generation actually produces,
# and what a state transition leaves behind. Every bug fixed in this branch lived
# in that gap.
#
# These boot the real scene. That needs Sprites/ and Music/, which are untracked
# (see README), so a code-only clone reports these as pending rather than failing
# -- run tools/stub_assets.py first to make them run anywhere.

const LEVEL_PATH := "res://Levels/main_level.tscn"
const BOSS_PATH := "res://Levels/final_level.tscn"
const MainRoom := preload("res://Levels/level_generator_script/main_room.gd")

# Frames to let _ready, the first _process and any deferred calls settle.
const SETTLE_FRAMES := 3

var _level: Node2D

# Booting a floor is expensive -- generation runs a 600-step walk and then a
# terrain-connect over the whole authored tile block. The tests that only look at
# what generation produced share one floor between them; only the ones where
# _ready()'s own effects are on trial pay for a fresh boot.
var _shared_level: Node2D
var _shared_boss: Node2D


func before_each():
	PlayerData.reset_run()
	_level = null


func after_each():
	if is_instance_valid(_level):
		_level.queue_free()
		_level = null
	PlayerData.reset_run()


func after_all():
	for level in [_shared_level, _shared_boss]:
		if is_instance_valid(level):
			level.queue_free()


# Boots once and freezes the result. Processing is disabled straight after so a
# shared floor cannot keep writing to PlayerData between tests -- its _process
# banks the clock and drives the loading screen.
func _shared(path := LEVEL_PATH):
	var cached: Node2D = _shared_boss if path == BOSS_PATH else _shared_level
	if is_instance_valid(cached):
		return cached
	var packed = load(path)
	if packed == null:
		return null
	cached = packed.instantiate()
	add_child(cached)
	for _i in SETTLE_FRAMES:
		await get_tree().process_frame
	cached.process_mode = Node.PROCESS_MODE_DISABLED
	if path == BOSS_PATH:
		_shared_boss = cached
	else:
		_shared_level = cached
	return cached


# Boots the floor and returns it, or null when the assets are not present.
func _boot(path := LEVEL_PATH):
	var packed = load(path)
	if packed == null:
		return null
	_level = packed.instantiate()
	add_child(_level)
	for _i in SETTLE_FRAMES:
		await get_tree().process_frame
	return _level


func _skip_without_assets(level) -> bool:
	if level == null:
		pending("needs Sprites/ and Music/ -- run tools/stub_assets.py")
		return true
	return false


func _children_named(level: Node, script_path: String) -> Array:
	var found := []
	for child in level.get_children():
		# Annotated rather than inferred: get_script() returns Variant, and this
		# project treats inference from a Variant as an error, so `:=` here is a
		# hard parse error and the whole script fails to load. GUT's own loader
		# is more permissive and runs it anyway -- the smoke test is what catches
		# this, which is the same trap main_room.gd and enemy_3.gd document.
		var script: Script = child.get_script()
		if script != null and script.resource_path == script_path:
			found.append(child)
	return found


# --- what generation actually produces ------------------------------------

func test_a_floor_places_exactly_one_player():
	var level = await _shared()
	if _skip_without_assets(level): return

	var players := []
	for child in level.get_children():
		if child.name == "Player":
			players.append(child)
	assert_eq(players.size(), 1, "a floor did not produce exactly one player")


func test_a_floor_places_an_exit():
	var level = await _shared()
	if _skip_without_assets(level): return

	var exits := _children_named(level,
		"res://interactables/interactable_script/exit.gd")
	assert_eq(exits.size(), 1, "a floor produced no way off it")


func test_the_player_and_the_exit_are_not_on_top_of_each_other():
	var level = await _shared()
	if _skip_without_assets(level): return

	var player: Node2D = level.get_node_or_null("Player")
	var exits := _children_named(level,
		"res://interactables/interactable_script/exit.gd")
	assert_gt((player.position - (exits[0] as Node2D).position).length(), 64.0,
		"the exit was placed on the spawn")


func test_a_floor_spawns_enemies():
	var level = await _shared()
	if _skip_without_assets(level): return

	var enemies := 0
	for child in level.get_children():
		if child is CharacterBody2D and child.name != "Player":
			enemies += 1
	assert_gt(enemies, 0, "an empty floor")


func test_a_floor_stays_inside_the_enemy_budget():
	# The cap this branch added. Unbudgeted, the level-18 passes ask for ~300
	# bodies; at level 1 the real question is only that the cap is not undershot
	# or bypassed.
	var level = await _shared()
	if _skip_without_assets(level): return

	var enemies := 0
	for child in level.get_children():
		if child is CharacterBody2D and child.name != "Player":
			enemies += 1
	assert_lte(enemies, MainRoom.MAX_FLOOR_ENEMIES,
		"a floor spawned past its own enemy budget")


func test_the_walker_carved_a_map():
	var level = await _shared()
	if _skip_without_assets(level): return

	assert_gt(level.map.size(), 100, "the floor was barely carved")
	# One apart, not equal: instance_player() pops the spawn cell off the front
	# of `map` so nothing else spawns on top of the player, but the cell stays in
	# the lookup because it is still floor the player has to be able to stand on.
	assert_eq(level.map.size(), level.floor_lookup.size() - 1,
		"the spawn cell was not taken out of the spawn pool exactly once")


# --- what _ready() puts back ----------------------------------------------

func test_loading_a_floor_clears_player_is_dead():
	# The bug this exists for: player_is_dead was only ever cleared by
	# reset_run(), and the death path re-asserts it immediately afterwards so the
	# outgoing level can pick the restart scene. Nothing put it back down, so
	# every floor after a death ran with the clock frozen (GUI reads this to
	# pause it) and the gun no longer aiming (target_mouse returns early on it).
	PlayerData.player_is_dead = true
	var level = await _boot()
	if _skip_without_assets(level): return

	assert_false(PlayerData.player_is_dead,
		"the floor loaded still believing the player was dead")


func test_loading_a_floor_clears_the_boss_room_flag():
	# final_level is a static and the boss room only ever set it true, so one
	# visit permanently gave every later floor boss-room aggression and a 0.1s
	# invulnerability window.
	PlayerData.final_level = true
	var level = await _boot()
	if _skip_without_assets(level): return

	assert_false(PlayerData.final_level,
		"a procedural floor ran with the boss room's difficulty")


func test_loading_a_floor_consumes_the_one_floor_purchases():
	PlayerData.cull_next = true
	PlayerData.bandolier_next = true
	var level = await _boot()
	if _skip_without_assets(level): return

	assert_true(PlayerData.cull_active, "Culling Order never took effect")
	assert_false(PlayerData.cull_next, "Culling Order can fire again next floor")
	assert_true(PlayerData.bandolier_active, "Bandolier never took effect")
	assert_false(PlayerData.bandolier_next, "Bandolier can fire again next floor")


func test_loading_a_floor_starts_the_clock():
	var level = await _boot()
	if _skip_without_assets(level): return

	assert_gt(level.get_node("map_timer").time_left, 0.0,
		"the floor clock never started")


func test_overclock_lengthens_the_clock_it_was_bought_for():
	PlayerData.bonus_time_next = 40.0
	var level = await _boot()
	if _skip_without_assets(level): return

	assert_eq(PlayerData.floor_bonus_time, 40.0,
		"the bought seconds were not handed to the floor")
	assert_eq(PlayerData.bonus_time_next, 0.0,
		"Overclock was left armed for the floor after this one too")
	assert_gt(level.get_node("map_timer").time_left, 121.0,
		"the clock did not actually get the extra time")


# --- transitions ----------------------------------------------------------

func test_reaching_the_exit_banks_the_leftover_clock():
	var level = await _boot()
	if _skip_without_assets(level): return

	PlayerData.reached_exit = true
	await get_tree().process_frame
	assert_gt(PlayerData.banked_time, 0.0,
		"standing on the exit banked nothing")


func test_reaching_the_exit_stops_the_clock():
	var level = await _boot()
	if _skip_without_assets(level): return

	PlayerData.reached_exit = true
	await get_tree().process_frame
	assert_true(level.get_node("map_timer").paused,
		"the clock kept running after the floor was cleared")


func test_the_bank_is_only_taken_once_however_long_you_stand_there():
	var level = await _boot()
	if _skip_without_assets(level): return

	PlayerData.reached_exit = true
	await get_tree().process_frame
	var banked: float = PlayerData.banked_time
	for _i in 5:
		await get_tree().process_frame
	assert_almost_eq(PlayerData.banked_time, banked, 0.01,
		"the clock was banked again on every frame spent on the exit")


# --- the boss room --------------------------------------------------------

func test_the_boss_room_is_wired_to_end_the_run():
	# Killing the boss used to do nothing: it freed itself, the escort spawner
	# paused, and the room stayed up forever with no exit and no next_level_timer.
	# The connection is asserted rather than the ending being played out, because
	# on_boss_defeated() changes scene and would take the test runner with it.
	var level = await _shared(BOSS_PATH)
	if _skip_without_assets(level): return

	assert_not_null(level.boss, "the boss room has no boss in it")
	assert_true(level.boss.has_signal("defeated"),
		"the boss cannot report being killed")
	assert_true(level.boss.defeated.is_connected(level.on_boss_defeated),
		"nothing is listening for the boss dying, so the run has no ending")


func test_the_boss_room_asserts_its_own_difficulty_flag():
	PlayerData.final_level = false
	var level = await _boot(BOSS_PATH)
	if _skip_without_assets(level): return

	assert_true(PlayerData.final_level,
		"the boss room ran without its own difficulty flag set")

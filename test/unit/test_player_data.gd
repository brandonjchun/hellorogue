extends GutTest

# PlayerData holds the whole run in static vars, which means it lives for the
# life of the process and survives every scene change. That is what makes it
# fast, and it is also why two shipped bugs lived here: a debug health value
# that nothing reset on a cold boot, and a final_level flag that was set by the
# boss room and never cleared, silently changing the difficulty of every later
# run in the same session.
#
# Every test below resets first, for the same reason the game has to.

func before_each():
	PlayerData.reset_run()


func after_all():
	PlayerData.reset_run()


# --- starting constants ---------------------------------------------------

func test_starting_health_is_not_a_debug_value():
	# Regression: this was 9000, and the GUI read "+8988" on a fresh launch.
	assert_eq(PlayerData.STARTING_HEALTH, 24)


func test_starting_constants_are_sane():
	assert_gt(PlayerData.STARTING_AMMO, 0, "a run cannot start with no ammo")
	assert_gt(PlayerData.STARTING_BOSS_HEALTH, 0, "the boss cannot start dead")
	assert_gt(PlayerData.STARTING_BANK_CAP, 0.0, "the bank cannot start at zero capacity")
	assert_gt(PlayerData.SECOND_WIND_SECONDS, 0.0, "Second Wind must grant time")


func test_the_first_scene_exists():
	assert_true(ResourceLoader.exists(PlayerData.FIRST_SCENE),
		"FIRST_SCENE points at a scene that is not in the project")


# --- shop_due() -----------------------------------------------------------
#
# The exit increments `levels` before asking, so the floor just cleared is
# `levels - 1`.

func test_no_shop_before_the_first_floor_is_cleared():
	PlayerData.levels = 1
	assert_false(PlayerData.shop_due(), "a shop opened before any floor was cleared")


func test_no_shop_after_a_single_floor():
	PlayerData.levels = 2
	assert_false(PlayerData.shop_due())


func test_shop_after_every_third_floor():
	for cleared in [3, 6, 9, 12, 15, 18]:
		PlayerData.levels = cleared + 1
		assert_true(PlayerData.shop_due(),
			"no shop after clearing floor %d" % cleared)


func test_no_shop_on_the_floors_between():
	for cleared in [1, 2, 4, 5, 7, 8, 10, 11, 13, 14, 16, 17]:
		PlayerData.levels = cleared + 1
		assert_false(PlayerData.shop_due(),
			"a shop opened after clearing floor %d" % cleared)


func test_the_procedural_run_offers_exactly_six_shops():
	var shops := 0
	for levels in range(1, 20):
		PlayerData.levels = levels
		if PlayerData.shop_due():
			shops += 1
	assert_eq(shops, 6, "the procedural run should offer six shops")


func test_every_intermission_exit_past_nineteen_offers_a_shop():
	for levels in [20, 21, 22, 23, 30]:
		PlayerData.levels = levels
		assert_true(PlayerData.shop_due(),
			"no shop at level %d" % levels)


func test_shop_due_handles_a_zero_level_without_erroring():
	# Nothing should ever set this, but `cleared` goes negative if anything does
	# and the modulo has to not report a shop.
	PlayerData.levels = 0
	assert_false(PlayerData.shop_due())


# --- reset_run() ----------------------------------------------------------

func test_reset_restores_health_and_ammo():
	PlayerData.health = 1
	PlayerData.ammo = 0
	PlayerData.reset_run()
	assert_eq(PlayerData.health, PlayerData.STARTING_HEALTH)
	assert_eq(PlayerData.ammo, PlayerData.STARTING_AMMO)


func test_reset_sends_the_run_back_to_the_first_floor():
	PlayerData.levels = 17
	PlayerData.reset_run()
	assert_eq(PlayerData.levels, 1)


func test_reset_clears_the_final_level_flag():
	# Regression: the boss room set this and nothing cleared it. Because it is a
	# static, one visit gave every later run a 0.1s invulnerability window
	# instead of 0.75s, with nothing on screen to explain why.
	PlayerData.final_level = true
	PlayerData.reset_run()
	assert_false(PlayerData.final_level,
		"final_level leaked out of the boss room into the next run")


func test_reset_restores_boss_health():
	PlayerData.boss_health = 1
	PlayerData.reset_run()
	assert_eq(PlayerData.boss_health, PlayerData.STARTING_BOSS_HEALTH)


func test_reset_empties_the_bank():
	PlayerData.banked_time = 95.0
	PlayerData.reset_run()
	assert_eq(PlayerData.banked_time, 0.0, "banked time survived into a new run")


func test_reset_undoes_vault_expansions():
	# Vault raises the cap permanently *within a run*. A new run has to pay again.
	PlayerData.bank_cap = 999.0
	PlayerData.reset_run()
	assert_eq(PlayerData.bank_cap, PlayerData.STARTING_BANK_CAP,
		"a purchased bank capacity carried into the next run for free")


func test_reset_clears_bonus_time():
	PlayerData.bonus_time_next = 40.0
	PlayerData.floor_bonus_time = 40.0
	PlayerData.reset_run()
	assert_eq(PlayerData.bonus_time_next, 0.0)
	assert_eq(PlayerData.floor_bonus_time, 0.0)


func test_reset_clears_one_floor_purchases():
	PlayerData.cull_next = true
	PlayerData.cull_active = true
	PlayerData.bandolier_next = true
	PlayerData.bandolier_active = true
	PlayerData.reset_run()
	assert_false(PlayerData.cull_next, "Culling Order carried into a new run")
	assert_false(PlayerData.cull_active, "an active cull carried into a new run")
	assert_false(PlayerData.bandolier_next, "Bandolier carried into a new run")
	assert_false(PlayerData.bandolier_active, "an active bandolier carried into a new run")


func test_reset_clears_the_shrine_boon():
	# haste rides the same one-floor pattern as cull and bandolier, but is set
	# mid-floor by a shrine rather than bought between floors.
	PlayerData.haste_next = true
	PlayerData.haste_active = true
	PlayerData.reset_run()
	assert_false(PlayerData.haste_next, "a queued shrine boon carried into a new run")
	assert_false(PlayerData.haste_active, "an active shrine boon carried into a new run")


func test_reset_clears_second_wind():
	PlayerData.second_wind = true
	PlayerData.reset_run()
	assert_false(PlayerData.second_wind, "a paid-for Second Wind carried into a new run")


func test_reset_closes_the_shop():
	PlayerData.shop_pending = true
	PlayerData.shop_open = true
	PlayerData.reset_run()
	assert_false(PlayerData.shop_pending, "a pending shop survived a reset")
	assert_false(PlayerData.shop_open, "the shop was still flagged open after a reset")


func test_reset_clears_the_run_ending_flags():
	PlayerData.player_is_dead = true
	PlayerData.reached_exit = true
	PlayerData.intermission_levels = true
	PlayerData.pause_active = true
	PlayerData.reset_run()
	assert_false(PlayerData.player_is_dead)
	assert_false(PlayerData.reached_exit)
	assert_false(PlayerData.intermission_levels)
	assert_false(PlayerData.pause_active)
	assert_true(PlayerData.game_active, "the game was left inactive after a reset")
	assert_true(PlayerData.hurt_ready, "the player was left invulnerable after a reset")


func test_reset_is_idempotent():
	PlayerData.reset_run()
	var health: int = PlayerData.health
	var cap: float = PlayerData.bank_cap
	PlayerData.reset_run()
	assert_eq(PlayerData.health, health)
	assert_eq(PlayerData.bank_cap, cap)


# --- deliberately NOT reset ----------------------------------------------
#
# These two are pinned so that a future change to reset_run() has to be a
# decision rather than an accident.

func test_reset_leaves_the_screen_shake_setting_alone():
	# A display preference, not run state. Wiping it on death would silently
	# undo something the player chose in the options menu.
	PlayerData.screen_shake_enabled = true
	PlayerData.reset_run()
	assert_true(PlayerData.screen_shake_enabled,
		"a user setting was wiped by a run reset")
	PlayerData.screen_shake_enabled = false


func test_reset_leaves_next_scene_alone():
	# next_scene is owned by loading_screen_intermission.reset_next_scene(),
	# which is what the arena levels call on death. reset_run() deliberately
	# does not touch it -- if that ever changes, the two will fight.
	PlayerData.next_scene = "res://Levels/final_level.tscn"
	PlayerData.reset_run()
	assert_eq(PlayerData.next_scene, "res://Levels/final_level.tscn",
		"reset_run() has started competing with reset_next_scene()")
	PlayerData.next_scene = PlayerData.FIRST_SCENE

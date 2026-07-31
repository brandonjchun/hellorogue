extends Node

class_name PlayerData

# Run-scoped state. These are `static`, so they live for the whole process and
# survive scene changes -- which is why every one of them has to be put back
# explicitly when a new run starts. See reset_run().

const STARTING_HEALTH := 24
const STARTING_AMMO := 50
const STARTING_BOSS_HEALTH := 500
const FIRST_SCENE := "res://Levels/intermission_level.tscn"

# Seconds left on the clock used to be thrown away, so the timer could only ever
# take something from the player. Now the exit deposits them here and the shop
# spends them, which turns "clear the floor or run for the portal?" into a real
# question on every floor instead of a pure loss either way.
const STARTING_BANK_CAP := 120.0
# Refill granted when Second Wind absorbs a clock that hit zero.
const SECOND_WIND_SECONDS := 60.0

# Was 9000. That is a debug value, and nothing reset it on a cold boot: the only
# two assignments of 24 are on death and in reset_player_data_states(), which
# had no callers. A fresh launch started the player with 9000 HP and the GUI
# reading "+8988".
static var health = STARTING_HEALTH
static var ammo = STARTING_AMMO
static var levels = 1
static var sound_selecter = 0
static var reached_exit = false
static var toggle_loading_screen = false
static var hurt_ready = true
static var degrees_to_player = 0.0
static var player_is_dead = false
static var game_mouse = false
static var pause_active = false
static var game_active = true
static var intermission_levels = false
static var final_level = false
static var next_scene = FIRST_SCENE
static var screen_shake_enabled = false
static var boss_health = STARTING_BOSS_HEALTH
static var reset_button_hit = false

# --- banked time ---

# Unspent seconds, carried between floors. The cap is what stops a player who
# rushes everything from arriving at the boss with an unspendable pile; it is
# itself a shop upgrade, so hoarding is a thing you invest in rather than a
# thing you get for free.
static var banked_time := 0.0
static var bank_cap := STARTING_BANK_CAP

# Seconds bought at the shop. `bonus_time_next` is granted to the following
# floor and consumed into `floor_bonus_time` when that floor loads.
#
# Bonus seconds are deliberately not bankable -- see main_room.bank_floor_time().
# If they were, Overclock would refund more than it cost and buying it would
# stop being a decision.
static var bonus_time_next := 0.0
static var floor_bonus_time := 0.0

# Purchases that last exactly one floor. Each is consumed into its `_active`
# twin as the next floor loads, so the flag cannot leak into the floor after it.
static var cull_next := false
static var cull_active := false
static var bandolier_next := false
static var bandolier_active := false

# Shrine boon: movement speed, this floor only. Shrines are touched mid-floor
# rather than bought between floors, so shrine.gd sets `haste_active` directly
# and `haste_next` exists so the same boon can be granted ahead of a floor
# later. Both are consumed in main_room._ready() alongside the pair above.
static var haste_next := false
static var haste_active := false

# One-shot insurance. Unlike the two above it survives floors until it is spent
# absorbing a clock that ran out.
static var second_wind := false

# Set by the exit when the floor just cleared ends a three-floor block, so the
# level opens the shop instead of going straight to the loading screen.
static var shop_pending := false
# True only while the panel is up. The pause menu reads it so ESC cannot unpause
# the tree out from under the shop.
static var shop_open := false

# Whether clearing the current floor should open the shop.
#
# The exit increments `levels` before this is asked, so the floor just finished
# is `levels - 1`. Multiples of three up to 18 give the six shops across the
# procedural run; every intermission exit past that gets one too, restricted to
# health by arena_level.
static func shop_due() -> bool:
	var cleared: int = levels - 1
	if cleared >= 19:
		return true
	return cleared > 0 and cleared % 3 == 0

# Puts every run-scoped value back to its starting state.
#
# `final_level` in particular was set true by the boss room and never cleared
# anywhere. Because these are statics, that stuck for the rest of the process:
# after reaching the boss once, every later run gave the player a 0.1s
# invulnerability window instead of 0.75s and every enemy a 0.3s spawn freeze
# with a 2.5-4x aggro radius, with nothing on screen to explain why.
static func reset_run() -> void:
	health = STARTING_HEALTH
	ammo = STARTING_AMMO
	levels = 1
	sound_selecter = 0
	boss_health = STARTING_BOSS_HEALTH
	hurt_ready = true
	player_is_dead = false
	reached_exit = false
	intermission_levels = false
	final_level = false
	pause_active = false
	game_active = true
	banked_time = 0.0
	bank_cap = STARTING_BANK_CAP
	bonus_time_next = 0.0
	floor_bonus_time = 0.0
	cull_next = false
	cull_active = false
	bandolier_next = false
	bandolier_active = false
	haste_next = false
	haste_active = false
	second_wind = false
	shop_pending = false
	shop_open = false

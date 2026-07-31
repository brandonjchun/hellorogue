extends Node

class_name PlayerData

# Run-scoped state. These are `static`, so they live for the whole process and
# survive scene changes -- which is why every one of them has to be put back
# explicitly when a new run starts. See reset_run().

const STARTING_HEALTH := 24
const STARTING_AMMO := 50
const STARTING_BOSS_HEALTH := 500
const FIRST_SCENE := "res://Levels/intermission_level.tscn"

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

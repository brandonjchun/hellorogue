extends Node

class_name player_data

static var health = 9000
static var ammo = 50
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
static var next_scene = "res://Levels/intermission_level.tscn"
static var screen_shake_enabled = false
static var boss_health = 500
static var reset_button_hit = false

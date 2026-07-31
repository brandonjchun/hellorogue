extends Node2D

class_name ArenaLevel

# Shared behaviour for the four hand-built levels (the three intermissions and
# the final boss room). Those scripts were ~2,800 lines between them and about
# 80% of that was the same code four times over: identical loading-screen
# handling, identical pause-menu wiring, and thousands of lines of hand-typed
# node references that this class now gathers in a loop.
#
# Subclasses set level_number / theme_track / wave_sizes, then call super._ready().

@onready var player_scene: PackedScene = preload("res://Entities/Scenes/Player/player.tscn")
@onready var enemy1_scene: PackedScene = preload("res://Entities/Scenes/Enemies/enemy_1.tscn")
@onready var enemy2_scene: PackedScene = preload("res://Entities/Scenes/Enemies/enemy_2.tscn")
@onready var enemy3_scene: PackedScene = preload("res://Entities/Scenes/Enemies/enemy_3.tscn")
@onready var enemy4_scene: PackedScene = preload("res://Entities/Scenes/Enemies/enemy_4.tscn")
@onready var enemy5_scene: PackedScene = preload("res://Entities/Scenes/Enemies/enemy_5.tscn")
@onready var silverspikes_scene: PackedScene = preload("res://interactables/scenes/dead_area.tscn")
@onready var redspikes_scene: PackedScene = preload("res://interactables/scenes/redspikes.tscn")

@onready var gui := $GUI_intermission
@onready var pause_menu_canvas := $CanvasLayer
@onready var pause_menu := $CanvasLayer/PauseMenu
@onready var main_mouse_icon := $CanvasLayer/main_mouse_icon
@onready var loading_screen_canvas := $CanvasLayer2
@onready var loading_screen_intermission := $CanvasLayer2/loading_screen_intermission
@onready var player_spawn: Marker2D = $player_spawn

# final_level has no exit and no next_level_timer; the others do.
@onready var exit: Node2D = get_node_or_null("exit")
@onready var next_level_timer: Timer = get_node_or_null("next_level_timer")

# --- subclass configuration ---
var level_number := 19
var theme_track := ""
# Drives PlayerData.final_level, which enemies and the player both read in
# their own _ready. It has to be settled before spawn_player() runs.
var is_final_level := false
# Enemies spawned per wave, indexed by enemy type 0-3.
var wave_sizes := [8, 6, 2, 4]
# Markers the periodic enemy waves spawn on. Kept untyped so subclasses can
# hand it a duplicate() of another marker list without typed-array friction.
var enemy_markers: Array = []

# These levels spawn on a timer forever and nothing ever despawns. With the
# wave-spawn bug fixed (see spawn_wave) the real spawn counts finally take
# effect, and unbounded they will bury the frame rate within a minute.
@export var max_live_enemies := 120

var change_scenes_once := 0
var _live_enemies := 0
var _reset_requested := false

func _ready() -> void:
	PlayerData.game_active = true
	PlayerData.levels = level_number
	PlayerData.hurt_ready = true
	PlayerData.reached_exit = false
	# Every level asserts this, so the flag cannot stay stuck on from a previous
	# run no matter which path got us here. It was only ever set true, never
	# cleared, and it is a static -- so one visit to the boss room permanently
	# changed the difficulty of every later run in the same process.
	PlayerData.final_level = is_final_level

	spawn_player()

	if theme_track != "":
		ThemePlayer.play_only(theme_track)

	pause_menu.exit_pause_menu.connect(on_exit_pause_menu)
	pause_menu.enter_pause_menu.connect(on_enter_pause_menu)

func _process(_delta: float) -> void:
	# reset_next_scene() issues a threaded load request. The original called it
	# from _process with no guard, so once the player died it fired a fresh
	# request every single frame until the scene actually swapped.
	if PlayerData.player_is_dead and not _reset_requested:
		_reset_requested = true
		loading_screen_intermission.reset_next_scene()

	if not PlayerData.toggle_loading_screen:
		return

	visible = false
	gui.visible = false
	pause_menu.visible = false

	if loading_screen_canvas.layer < 4:
		loading_screen_canvas.layer = 4
		loading_screen_canvas.visible = true
		loading_screen_intermission.visible = true
		loading_screen_intermission.z_index = 10

	if change_scenes_once == 0:
		if PlayerData.player_is_dead:
			loading_screen_intermission.reset_next_scene()
		else:
			loading_screen_intermission.load_next_scene()
		if next_level_timer:
			next_level_timer.start()
		change_scenes_once += 1
		PlayerData.toggle_loading_screen = false

# --- spawning helpers ---

func spawn_player() -> void:
	var player := player_scene.instantiate() as Node2D
	add_child(player)
	player.position = player_spawn.position

# Gathers Marker2D children by name prefix, replacing the blocks of 320
# hand-written `@onready var spikes_N = $spikesN` lines and the 300-element
# array literals that followed them. Timers named with the same prefix
# (spikes_timer, enemy_spawn) are excluded by the Marker2D type check.
func collect_markers(prefix: String) -> Array[Marker2D]:
	var markers: Array[Marker2D] = []
	for child in get_children():
		if child is Marker2D and String(child.name).begins_with(prefix):
			markers.append(child as Marker2D)
	return markers

# Spawns `count` enemies of one type across the given markers.
#
# Every caller used to read:
#     enemy = scene.instantiate()      # once
#     for i in range(count):
#         enemy.position = ...
#         add_child(enemy)             # ...added `count` times
# which spawns exactly one enemy and logs "node already has a parent" for the
# rest. Waves advertised as 12 enemies were delivering 1.
func spawn_wave(scene: PackedScene, count: int, markers: Array) -> void:
	if markers.is_empty():
		return
	for i in count:
		if _live_enemies >= max_live_enemies:
			return
		var enemy := scene.instantiate() as Node2D
		enemy.position = (markers.pick_random() as Node2D).position
		_live_enemies += 1
		enemy.tree_exited.connect(_on_enemy_freed)
		add_child(enemy)

func _on_enemy_freed() -> void:
	_live_enemies -= 1

func enemy_scene_for(index: int) -> PackedScene:
	match index:
		0: return enemy1_scene
		1: return enemy2_scene
		2: return enemy3_scene
		_: return enemy4_scene

func _on_enemy_spawn_timeout() -> void:
	var enemy_type := randi_range(0, 3)
	spawn_wave(enemy_scene_for(enemy_type), wave_sizes[enemy_type], enemy_markers)
	$enemy_spawn.start()

# Converts one unused marker into a spike trap.
#
# `reserve` is how many markers to leave untouched, preserving the original
# "stop before the room is completely full" behaviour but not the two bugs that
# came with it. The old version indexed `randi_range(0, size - reserve)`, so it only
# ever drew from the front of the list and the last `reserve` markers were
# unreachable rather than merely held back; and it called pop_at(i) (which
# already removes) followed by remove_at(i), silently deleting a second,
# unrelated marker on every tick.
func spawn_random_spike(markers: Array, reserve: int) -> void:
	if markers.size() <= reserve:
		return
	var source := markers.pop_at(randi_range(0, markers.size() - 1)) as Node2D
	var scene: PackedScene = silverspikes_scene if randi_range(0, 1) == 0 else redspikes_scene
	var spike := scene.instantiate() as Node2D
	spike.position = source.position
	add_child(spike)

# --- pause menu ---

func on_exit_pause_menu() -> void:
	pause_menu_canvas.visible = false
	pause_menu.visible = false
	main_mouse_icon.visible = false
	pause_menu_canvas.layer = -4

func on_enter_pause_menu() -> void:
	pause_menu_canvas.visible = true
	pause_menu.visible = true
	main_mouse_icon.visible = true
	pause_menu_canvas.layer = 4

# final_level.tscn also wired these two signals in the scene file, to
# _on_pause_menu_enter_pause_menu / _on_pause_menu_exit_pause_menu -- names that
# were never defined, so opening the pause menu in the boss room threw
# "nonexistent function" every time. Those scene connections are gone; all four
# levels now connect in _ready above, like the rest of the game.

func _on_next_level_timer_timeout() -> void:
	visible = true
	gui.visible = true
	pause_menu.visible = true
	loading_screen_canvas.layer = -10
	loading_screen_canvas.visible = false
	loading_screen_intermission.visible = false
	loading_screen_intermission.z_index = -10
	PlayerData.toggle_loading_screen = false
	change_scenes_once = 0

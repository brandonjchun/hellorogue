extends Node2D

@onready var player_scene = preload("res://Entities/Scenes/Player/player.tscn")
@onready var exit_scene = preload("res://interactables/scenes/exit.tscn")
@onready var enemy1_scene = preload("res://Entities/Scenes/Enemies/enemy_1.tscn")
@onready var enemy2_scene = preload("res://Entities/Scenes/Enemies/enemy_2.tscn")
@onready var enemy3_scene = preload("res://Entities/Scenes/Enemies/enemy_3.tscn")
@onready var enemy4_scene = preload("res://Entities/Scenes/Enemies/enemy_4.tscn")
@onready var enemy5_scene = preload("res://Entities/Scenes/Enemies/enemy_5.tscn")
@onready var silverspikes_scene = preload("res://interactables/scenes/dead_area.tscn")
@onready var redspikes_scene = preload("res://interactables/scenes/redspikes.tscn")
@onready var main_level = $"."
@onready var gui = $GUI

var lev = PlayerData.levels - 1
@onready var pause_menu_canvas = $pause_menu
@onready var pause_menu = $pause_menu/PauseMenu
@onready var main_mouse_icon = $pause_menu/main_mouse_icon

@onready var loading_screen_canvas = $loading_screen_canvas
@onready var loading_screen = $loading_screen_canvas/loading_screen
@onready var animation = $loading_screen_canvas/loading_screen/animation
@onready var loading_anim = $loading_screen_canvas/loading_screen/anim
@onready var loading_anim2 = $loading_screen_canvas/loading_screen/loading

@onready var tilemap_water = $TileMap3
@onready var tilemap_mix = $TileMap
@onready var tilemap_hell = $TileMap2
@onready var ground = $ground
@onready var ground2 = $ground2
@onready var ground3 = $ground3

const TILE_SIZE := 16

# Base playfield, and how much it grows per 3-level difficulty tier.
@export var base_borders := Rect2(1, 1, 200, 100)
@export var borders_growth_per_tier := 40

# Cells of solid rock kept between the playfield and the edge of the authored
# tile block. Without this the walker can carve right up to the edge and leave
# an opening the player can walk out through.
const WALL_MARGIN := 2

# Music tier -> ThemePlayer track name. Index is PlayerData.sound_selecter.
const LEVEL_THEMES := ["makuhita", "silentchasm", "steel", "lapis", "blazepeak",
	"sinister"]

var borders: Rect2
var walker
var map
var floor_lookup := {}
var ground_layer = 0
var change_scenes_once = 0
var loading_screen_timeout = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$loading_screen_timer.wait_time = randf_range(1.5, 2.5)
	PlayerData.hurt_ready = true
	PlayerData.reached_exit = false
	PlayerData.game_active = true
	# The boss room sets this true and nothing ever cleared it. Because it is a
	# static it survived scene changes, so every procedural level after a boss
	# visit silently ran with boss-room enemy aggression and a 0.1s player
	# invulnerability window.
	PlayerData.final_level = false
	randomize()
	if PlayerData.levels < 6:
		generate_level(tilemap_water)
		ground2.visible = false
	elif PlayerData.levels >= 6 and PlayerData.levels < 12:
		tilemap_water.tile_set = tilemap_mix.tile_set
		generate_level(tilemap_water)
	elif PlayerData.levels >= 12:
		tilemap_water.tile_set = tilemap_hell.tile_set
		generate_level(tilemap_water)

	PlayerData.sound_selecter = clampi(int(PlayerData.levels / 3.0), 0, LEVEL_THEMES.size() - 1)
	# Selecting the track is level-load state, not per-frame state. This used to
	# run a seven-branch play/stop cascade inside _process, 60 times a second.
	ThemePlayer.play_only(LEVEL_THEMES[PlayerData.sound_selecter])

	$map_timer.start()
	$time_running_out_timer.wait_time = $map_timer.wait_time - 10
	$time_running_out_timer.start()

	pause_menu.exit_pause_menu.connect(on_exit_pause_menu)
	pause_menu.enter_pause_menu.connect(on_enter_pause_menu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if PlayerData.reached_exit:
		$map_timer.paused = true
		$time_running_out_timer.paused = true

	if PlayerData.reached_exit or PlayerData.toggle_loading_screen:
		PlayerData.hurt_ready = false

	if PlayerData.toggle_loading_screen:
		main_level.visible = false
		gui.visible = false
		pause_menu.visible = false
		if loading_screen_canvas.layer < 4:
			loading_screen_canvas.layer = 4
			loading_screen_canvas.visible = true
			loading_screen.visible = true
			loading_screen.z_index = 10
			animation.z_index = 12
			animation.visible = true
			PlayerData.hurt_ready = false
			loading_anim.play("fly")
			loading_anim2.play("loading")
			$loading_screen_timer.start()

		if change_scenes_once == 0 and loading_screen_timeout:
			$next_level_timer.start()
			change_scenes_once += 1
			PlayerData.toggle_loading_screen = false
			PlayerData.reset_button_hit = false

# The walker must never carve outside the authored block of wall tiles. The
# playfield grew 40 cells per tier while the authored block stayed fixed, so
# from level 15 on the walk ran off the end of it: no wall tiles had ever been
# placed out there, nothing got drawn, and the player could stroll off the map.
func compute_borders(tilemap: TileMap) -> Rect2:
	var growth := borders_growth_per_tier * floor(lev / 3.0)
	var desired := Rect2(base_borders.position,
		base_borders.size + Vector2(growth, growth))

	var authored := Rect2(tilemap.get_used_rect()).grow(-WALL_MARGIN)
	var clamped := desired.intersection(authored)

	if clamped.size.x < 1 or clamped.size.y < 1:
		push_error("main_room: tilemap has no usable authored area; using base borders")
		return base_borders
	return clamped

func generate_level(tilemap):
	# get_used_rect() has to be read before clear() wipes the authored block.
	borders = compute_borders(tilemap)

	var start := Vector2(3 + floor(lev / 3.0), 5 + floor(lev / 3.0))
	if not borders.has_point(start):
		start = borders.position + Vector2.ONE

	walker = WalkerRoom.new(start, borders)
	map = walker.walk(int(600 + 900 * floor(lev / 3.0)))
	floor_lookup = walker.get_floor_lookup()

	var all_cells: Array = tilemap.get_used_cells(ground_layer)
	tilemap.clear()

	# `map` is an Array. Testing membership with map.has() scanned it linearly
	# for every authored cell -- roughly 88k cells x ~14k entries, which is
	# where the multi-second freeze on level load came from. The walker now
	# hands back a Dictionary so this is a hash lookup instead.
	var using_cells: Array = []
	for tile in all_cells:
		if not floor_lookup.has(Vector2(tile.x, tile.y)):
			using_cells.append(tile)

	tilemap.set_cells_terrain_connect(ground_layer, using_cells, ground_layer, ground_layer, false)
	# set_cells_terrain_path used to run here as well, over the same cells. It
	# treats its argument as an ordered path, which is meaningless for an
	# unordered cell soup, and it doubled the cost of the most expensive call
	# in level generation.

	instance_player()
	instance_exit()
	if PlayerData.levels >= 0:
		instance_enemy1()
	if PlayerData.levels >= 3:
		instance_silverspikes()
		instance_enemy2()
	if PlayerData.levels >= 3 and PlayerData.levels < 6:
		instance_enemy1()
		instance_enemy2()
	if PlayerData.levels >= 6:
		instance_enemy4()
		instance_redspikes()
	if PlayerData.levels >= 9 and PlayerData.levels < 12:
		instance_enemy1()
		instance_enemy2()
	if PlayerData.levels >= 12:
		instance_enemy3()
	if PlayerData.levels >= 15:
		instance_enemy3()
		instance_enemy4()

# Picks a carved floor cell and converts it to world space.
# The old call was `map.pick_random() * borders.position * TILE_SIZE`, which only
# behaved because borders.position happened to be (1, 1) -- any other origin
# would have scaled every spawn by it.
func random_floor_position() -> Vector2:
	return map.pick_random() * TILE_SIZE

func instance_player():
	var player = player_scene.instantiate()
	add_child(player)
	player.position = map.pop_front() * TILE_SIZE

func instance_exit():
	var exit = exit_scene.instantiate()
	add_child(exit)
	exit.position = walker.get_end_room().position * TILE_SIZE

func spawn_enemies(scene: PackedScene, count: int) -> void:
	for i in range(count):
		var enemy = scene.instantiate()
		enemy.position = random_floor_position()
		add_child(enemy)

func instance_enemy1():
	spawn_enemies(enemy1_scene, randi_range(maxi(1, PlayerData.levels), maxi(2, PlayerData.levels * 5)))

func instance_enemy2():
	spawn_enemies(enemy2_scene, randi_range(maxi(1, PlayerData.levels), maxi(3, PlayerData.levels * 4)))

func instance_enemy3():
	spawn_enemies(enemy3_scene, randi_range(maxi(1, PlayerData.levels), maxi(5, PlayerData.levels * 2)))

func instance_enemy4():
	spawn_enemies(enemy4_scene, randi_range(maxi(1, PlayerData.levels), maxi(4, PlayerData.levels * 3)))

func instance_enemy5():
	spawn_enemies(enemy5_scene, 1)

func instance_silverspikes():
	spawn_enemies(silverspikes_scene, randi_range(PlayerData.levels, 2 * PlayerData.levels))

func instance_redspikes():
	spawn_enemies(redspikes_scene, randi_range(PlayerData.levels, 2 * PlayerData.levels))

func _on_timer_timeout():
	PlayerData.toggle_loading_screen = true
	PlayerData.levels = 1
	PlayerData.reached_exit = false

func _on_next_level_timer_timeout():
	main_level.visible = true
	gui.visible = true
	pause_menu.visible = true
	loading_screen_canvas.layer = -2
	loading_screen_canvas.visible = false
	loading_screen.visible = false
	PlayerData.hurt_ready = false
	loading_screen.z_index = -2
	PlayerData.toggle_loading_screen = false
	change_scenes_once = 0

func on_exit_pause_menu():
	pause_menu_canvas.visible = false
	pause_menu.visible = false
	main_mouse_icon.visible = false
	pause_menu_canvas.layer = -4

func on_enter_pause_menu():
	pause_menu_canvas.visible = true
	pause_menu.visible = true
	main_mouse_icon.visible = true
	pause_menu_canvas.layer = 4

func _on_time_running_out_timer_timeout():
	$time_running_out.play()

func _on_loading_screen_timer_timeout():
	loading_screen_timeout = true
	loading_screen.load_next_scene()

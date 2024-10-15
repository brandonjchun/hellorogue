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
@onready var menu_scene = preload("res://Levels/menu.tscn")
@onready var main_level = $"."
@onready var gui = $GUI

var lev = player_data.levels-1
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


@export var borders = Rect2(1, 1, 200 + 10*(floor(lev/3)*4), 100 + 10*(floor(lev/3)*4))
var walker
var map
var ground_layer = 0
var change_scenes_once = 0
var loading_screen_timeout = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$loading_screen_timer.wait_time = randf_range(1.5, 2.5)
	player_data.hurt_ready = true
	player_data.reached_exit = false
	player_data.game_active = true
	randomize()
	if player_data.levels < 6:
		generate_level(tilemap_water)
		ground2.visible = false
	elif player_data.levels >= 6 and player_data.levels < 12:
		tilemap_water.tile_set = tilemap_mix.tile_set
		generate_level(tilemap_water)
	elif player_data.levels >= 12:
		tilemap_water.tile_set = tilemap_hell.tile_set
		generate_level(tilemap_water) 
		
	if player_data.levels >= 0 and player_data.levels < 3:
		player_data.sound_selecter = 0
	if player_data.levels >= 3 and player_data.levels < 6:
		player_data.sound_selecter = 1
	if player_data.levels >= 6 and player_data.levels < 9:
		player_data.sound_selecter = 2
	if player_data.levels >= 9 and player_data.levels < 12:
		player_data.sound_selecter = 3
	if player_data.levels >= 12 and player_data.levels <= 15:
		player_data.sound_selecter = 4
	if player_data.levels >= 15 and player_data.levels <= 18:
		player_data.sound_selecter = 5
	
	$map_timer.start()
	$time_running_out_timer.wait_time = $map_timer.wait_time - 10
	$time_running_out_timer.start()
	
	pause_menu.exit_pause_menu.connect(on_exit_pause_menu)
	pause_menu.enter_pause_menu.connect(on_enter_pause_menu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player_data.reached_exit:
		$map_timer.paused = true
		$time_running_out_timer.paused = true
	
	if player_data.reached_exit or player_data.toggle_loading_screen:
		player_data.hurt_ready = false
		
	if player_data.toggle_loading_screen:
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
			player_data.hurt_ready = false
			loading_anim.play("fly")
			loading_anim2.play("loading")
			$loading_screen_timer.start()

		if change_scenes_once == 0 and loading_screen_timeout:
			$next_level_timer.start()
			change_scenes_once += 1
			player_data.toggle_loading_screen = false
			player_data.reset_button_hit = false
	
	ThemePlayer.theme_questionairre_stop()
	ThemePlayer.theme_fileselect_stop()
	ThemePlayer.theme_ninetales_stop()
	
	match player_data.sound_selecter:
		0:
			ThemePlayer.theme_makuhita()
			ThemePlayer.theme_silentchasm_stop()
			ThemePlayer.theme_steel_stop()
			ThemePlayer.theme_lapis_stop()
			ThemePlayer.theme_blazepeak_stop()
			ThemePlayer.theme_sinister_stop()
			ThemePlayer.theme_magma_stop()
		1:
			ThemePlayer.theme_makuhita_stop()
			ThemePlayer.theme_silentchasm()
			ThemePlayer.theme_steel_stop()
			ThemePlayer.theme_lapis_stop()
			ThemePlayer.theme_blazepeak_stop()
			ThemePlayer.theme_sinister_stop()
			ThemePlayer.theme_magma_stop()
		2:
			ThemePlayer.theme_makuhita_stop()
			ThemePlayer.theme_silentchasm_stop()
			ThemePlayer.theme_steel()
			ThemePlayer.theme_lapis_stop()
			ThemePlayer.theme_blazepeak_stop()
			ThemePlayer.theme_sinister_stop()
			ThemePlayer.theme_magma_stop()
		3:
			ThemePlayer.theme_makuhita_stop()
			ThemePlayer.theme_silentchasm_stop()
			ThemePlayer.theme_steel_stop()
			ThemePlayer.theme_lapis()
			ThemePlayer.theme_blazepeak_stop()
			ThemePlayer.theme_sinister_stop()
			ThemePlayer.theme_magma_stop()
		4:
			ThemePlayer.theme_makuhita_stop()
			ThemePlayer.theme_silentchasm_stop()
			ThemePlayer.theme_steel_stop()
			ThemePlayer.theme_lapis_stop()
			ThemePlayer.theme_blazepeak()
			ThemePlayer.theme_sinister_stop()
			ThemePlayer.theme_magma_stop()
		5:
			ThemePlayer.theme_makuhita_stop()
			ThemePlayer.theme_silentchasm_stop()
			ThemePlayer.theme_steel_stop()
			ThemePlayer.theme_lapis_stop()
			ThemePlayer.theme_blazepeak_stop()
			ThemePlayer.theme_sinister()
			ThemePlayer.theme_magma_stop()

func generate_level(tilemap):
	walker = Walker_room.new(Vector2(3 + floor(lev/3), 5 + floor(lev/3)), borders)
	map = walker.walk(600 + 900 * floor(lev/3))

	var using_cells: Array = []
	var all_cells: Array = tilemap.get_used_cells(ground_layer)
	tilemap.clear()
	walker.queue_free()

	for tile in all_cells:
		if !map.has(Vector2(tile.x, tile.y)):
			using_cells.append(tile)

	tilemap.set_cells_terrain_connect(ground_layer, using_cells, ground_layer, ground_layer, false)
	tilemap.set_cells_terrain_path(ground_layer, using_cells, ground_layer, ground_layer, false)

	instance_player()
	instance_exit()
	if player_data.levels >= 0:
		instance_enemy1()
	if player_data.levels >= 3:
		instance_silverspikes()
		instance_enemy2()
	if player_data.levels >= 3 and player_data.levels < 6:
		instance_enemy1()
		instance_enemy2()
	if player_data.levels >= 6:
		instance_enemy4()
		instance_redspikes()
	if player_data.levels >= 9 and player_data.levels < 12:
		instance_enemy1()
		instance_enemy2()
	if player_data.levels >= 12:
		instance_enemy3()
	if player_data.levels >= 15:
		instance_enemy3()
		instance_enemy4()

func instance_player():
	var player = player_scene.instantiate()
	add_child(player)
	player.position = map.pop_front() * 16
	
func instance_exit():
	var exit = exit_scene.instantiate()
	add_child(exit)
	exit.position = walker.get_end_room().position * 16

func instance_enemy1():
	var enemies_count = randi_range(maxi(1, player_data.levels), maxi(2, player_data.levels*5))
	for i in range(enemies_count):
		var enemy = enemy1_scene.instantiate()
		enemy.position = (map.pick_random() * borders.position) * 16
		add_child(enemy)
		
func instance_enemy2():
	var enemies_count = randi_range(maxi(1, player_data.levels), maxi(3, player_data.levels*4))
	for i in range(enemies_count):
		var enemy = enemy2_scene.instantiate()
		enemy.position = (map.pick_random() * borders.position) * 16
		add_child(enemy)
		
func instance_enemy3():
	var enemies_count = randi_range(maxi(1, player_data.levels), maxi(5, player_data.levels*2))
	for i in range(enemies_count):
		var enemy = enemy3_scene.instantiate()
		enemy.position = (map.pick_random() * borders.position) * 16
		add_child(enemy)
		
func instance_enemy4():
	var enemies_count = randi_range(maxi(1, player_data.levels), maxi(4, player_data.levels*3))
	for i in range(enemies_count):
		var enemy = enemy4_scene.instantiate()
		enemy.position = (map.pick_random() * borders.position) * 16
		add_child(enemy)
		
func instance_enemy5():
	var enemy = enemy5_scene.instantiate()
	enemy.position = (map.pick_random() * borders.position) * 16
	add_child(enemy)

func instance_silverspikes():
	var silverspikes_count = randi_range(player_data.levels, 2*player_data.levels)
	for i in range(silverspikes_count):
		var silverspikes = silverspikes_scene.instantiate()
		silverspikes.position = (map.pick_random() * borders.position) * 16
		add_child(silverspikes)
		
func instance_redspikes():
	var redspikes_count = randi_range(player_data.levels, 2*player_data.levels)
	for i in range(redspikes_count):
		var redspikes = redspikes_scene.instantiate()
		redspikes.position = (map.pick_random() * borders.position) * 16
		add_child(redspikes)

func _on_timer_timeout():
	player_data.toggle_loading_screen = true
	player_data.levels = 1 
	player_data.reached_exit = false

func _on_next_level_timer_timeout():
	main_level.visible = true
	gui.visible = true
	pause_menu.visible = true
	loading_screen_canvas.layer = -2
	loading_screen_canvas.visible = false
	loading_screen.visible = false
	player_data.hurt_ready = false
	loading_screen.z_index = -2
	player_data.toggle_loading_screen = false
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

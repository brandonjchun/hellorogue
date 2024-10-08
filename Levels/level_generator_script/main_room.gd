extends Node2D

@onready var player_scene = preload("res://Entities/Scenes/Player/player.tscn")
@onready var exit_scene = preload("res://interactables/scenes/exit.tscn")
@onready var enemy1_scene = preload("res://Entities/Scenes/Enemies/enemy_1.tscn")
@onready var enemy2_scene = preload("res://Entities/Scenes/Enemies/enemy_2.tscn")
@onready var enemy3_scene = preload("res://Entities/Scenes/Enemies/enemy_3.tscn")
@onready var enemy4_scene = preload("res://Entities/Scenes/Enemies/enemy_4.tscn")
@onready var silverspikes_scene = preload("res://interactables/scenes/dead_area.tscn")
@onready var redspikes_scene = preload("res://interactables/scenes/redspikes.tscn")
@onready var menu_scene = preload("res://Levels/menu.tscn")
@onready var main_level = $"."
@onready var gui = $GUI

var lev = player_data.levels
@onready var pause_menu_canvas = $pause_menu
@onready var pause_menu = $pause_menu/PauseMenu
@onready var main_mouse_icon = $pause_menu/main_mouse_icon

@onready var loading_screen_canvas = $loading_screen_canvas
@onready var loading_screen = $loading_screen_canvas/loading_screen
@onready var loading_anim = $loading_screen_canvas/loading_screen/anim

@onready var tilemap = $TileMap
@export var borders = Rect2(1, 1, 200 + 2*lev, 100 + 2*lev)
var walker
var map
var ground_layer = 0
var change_scenes_once = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	player_data.game_active = true
	randomize()
	generate_level()
	if player_data.levels >= 1 and player_data.levels <= 3:
		player_data.sound_selecter = 0
	if player_data.levels > 3 and player_data.levels < 6:
		player_data.sound_selecter = 1
	if player_data.levels >= 6 and player_data.levels < 9:
		player_data.sound_selecter = 2
	if player_data.levels >= 9 and player_data.levels < 12:
		player_data.sound_selecter = 3
	if player_data.levels >= 12 and player_data.levels < 15:
		player_data.sound_selecter = 4
	if player_data.levels >= 15 and player_data.levels < 18:
		player_data.sound_selecter = 5
	if player_data.levels >= 18 and player_data.levels < 21:
		player_data.sound_selecter = 6
	if player_data.levels >= 21:
		player_data.sound_selecter = 7

	match player_data.sound_selecter:
		0:
			ThemePlayer.theme_wizards()
		1:
			ThemePlayer.theme_wizards_stop()
			ThemePlayer.theme_goodfight()
		2:
			ThemePlayer.theme_goodfight_stop()
			ThemePlayer.theme_steel()
		3:
			ThemePlayer.theme_steel_stop()
			ThemePlayer.theme_sinister()
		4:
			ThemePlayer.theme_sinister_stop()
			ThemePlayer.theme_magma()
		5:
			ThemePlayer.theme_magma_stop()
			ThemePlayer.theme_plumus()
		6:
			ThemePlayer.theme_plumus_stop()
			ThemePlayer.theme_final()
	
	$map_timer.start()
	$time_running_out_timer.wait_time = $map_timer.wait_time - 10
	$time_running_out_timer.start()
	
	pause_menu.exit_pause_menu.connect(on_exit_pause_menu)
	pause_menu.enter_pause_menu.connect(on_enter_pause_menu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
		
	if player_data.toggle_loading_screen:
		main_level.visible = false
		gui.visible = false
		pause_menu.visible = false
		if loading_screen_canvas.layer < 4:
			loading_screen_canvas.layer = 4
			loading_screen_canvas.visible = true
			loading_screen.visible = true
			loading_screen.z_index = 10
			loading_anim.play("jumping")

		if change_scenes_once == 0:
			loading_screen.load_next_scene()
			$next_level_timer.start()
			change_scenes_once += 1
			player_data.toggle_loading_screen = false
	
	ThemePlayer.theme_questionairre_stop()

func generate_level():
	walker = Walker_room.new(Vector2(3 + floor(lev/3), 5 + floor(lev/3)), borders)
	map = walker.walk(300 + 600 * floor(lev/3))

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
	if player_data.levels >= 2:
		instance_silverspikes()
	if player_data.levels >= 4:
		instance_enemy2()
	if player_data.levels >= 6:
		instance_enemy1()
		instance_enemy2()
	if player_data.levels >= 8:
		instance_enemy4()
		instance_redspikes()
	if player_data.levels >= 10:
		instance_enemy1()
		instance_enemy2()
		instance_enemy2()
		instance_enemy4()
		instance_enemy4()
	if player_data.levels >= 12:
		instance_enemy1()
		instance_enemy2()
		instance_enemy3()
		instance_enemy4()
		instance_enemy4()
	if player_data.levels >= 15:
		instance_enemy1()
		instance_enemy1()
		instance_enemy2()
		instance_enemy2()
		instance_enemy3()
		instance_enemy3()
		instance_enemy4()
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

func instance_silverspikes():
	var silverspikes_count = randi_range(3*player_data.levels,8)
	for i in range(silverspikes_count):
		var silverspikes = silverspikes_scene.instantiate()
		silverspikes.position = (map.pick_random() * borders.position) * 16
		add_child(silverspikes)
		
func instance_redspikes():
	var redspikes_count = randi_range(2*player_data.levels,12)
	for i in range(redspikes_count):
		var redspikes = redspikes_scene.instantiate()
		redspikes.position = (map.pick_random() * borders.position) * 16
		add_child(redspikes)

func _on_timer_timeout():
	player_data.toggle_loading_screen = true
	player_data.levels = 0 #set back to 0
	player_data.sound_selecter = 0
	player_data.hurt_ready = true

func _on_next_level_timer_timeout():
	main_level.visible = true
	gui.visible = true
	pause_menu.visible = true
	loading_screen_canvas.layer = -2
	loading_screen_canvas.visible = false
	loading_screen.visible = false
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

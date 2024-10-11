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
@onready var intermission_level = $"."
@onready var gui = $GUI_intermission
@onready var player_spawn = $player_spawn

@onready var enemy_spawner_1 = $enemy_spawner1
@onready var enemy_spawner_2 = $enemy_spawner2
@onready var enemy_spawner_3 = $enemy_spawner3
@onready var enemy_spawner_4 = $enemy_spawner4
@onready var enemy_spawner_5 = $enemy_spawner5
@onready var enemy_spawner_6 = $enemy_spawner6
@onready var enemy_spawner_7 = $enemy_spawner7
@onready var enemy_spawner_8 = $enemy_spawner8
@onready var enemy_spawner_9 = $enemy_spawner9
@onready var enemy_spawner_10 = $enemy_spawner10
@onready var enemy_spawner_11 = $enemy_spawner11
@onready var enemy_spawner_12 = $enemy_spawner12
@onready var enemy_spawner_13 = $enemy_spawner13

@onready var exit = $exit

@onready var main_mouse_icon = $CanvasLayer/main_mouse_icon
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var pause_menu_canvas = $CanvasLayer

@onready var loading_screen_canvas = $loading_screen_canvas
@onready var loading_screen = $loading_screen_canvas/loading_screen
@onready var loading_anim = $loading_screen_canvas/loading_screen/anim

@onready var tilemap = $TileMap3

var walker
var map
var ground_layer = 0
var change_scenes_once = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	player_data.game_active = true
	generate_level()
		
		
	ThemePlayer.theme_skytowersummit()
	ThemePlayer.theme_makuhita_stop()
	
	
	pause_menu.exit_pause_menu.connect(on_exit_pause_menu)
	pause_menu.enter_pause_menu.connect(on_enter_pause_menu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
		
	if player_data.toggle_loading_screen:
		intermission_level.visible = false
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
	ThemePlayer.theme_fileselect_stop()
	ThemePlayer.theme_ninetales_stop()

func generate_level():
	instance_player()
	instance_enemy1()
	instance_enemy1()
	instance_enemy1()
	instance_enemy1()
	instance_enemy1()
	instance_enemy1()
	instance_enemy1()
	instance_enemy1()
	instance_enemy1()
	instance_enemy1()
	instance_enemy1()
	instance_enemy1()
	instance_enemy1()
	instance_enemy2()
	instance_enemy2()
	instance_enemy2()
	instance_enemy2()
	instance_enemy2()
	instance_enemy2()
	instance_enemy2()
	instance_enemy2()
	instance_enemy2()
	instance_enemy2()
	instance_enemy4()
	instance_enemy4()
	instance_enemy4()
	instance_enemy4()
	instance_enemy4()
	instance_enemy4()
	instance_enemy4()
	instance_enemy4()
	instance_enemy4()
	instance_enemy4()
	instance_enemy4()
	instance_enemy4()
	instance_enemy3()
	instance_enemy3()
	instance_enemy3()
	instance_enemy3()

func instance_player():
	var player = player_scene.instantiate()
	add_child(player)
	player.position = player_spawn.position
	

func instance_enemy1():
	var enemies_count = randi_range(maxi(1, player_data.levels), maxi(2, player_data.levels*5))
	for i in range(enemies_count):
		var enemy = enemy1_scene.instantiate()
		var spawn_point = randi_range(1,14)
		match spawn_point:
			1:
				enemy.position = enemy_spawner_1.position
			2:
				enemy.position = enemy_spawner_2.position
			3:
				enemy.position = enemy_spawner_3.position
			4:
				enemy.position = enemy_spawner_4.position
			5:
				enemy.position = enemy_spawner_5.position
			6:
				enemy.position = enemy_spawner_6.position
			7:
				enemy.position = enemy_spawner_7.position
			8:
				enemy.position = enemy_spawner_8.position
			7:
				enemy.position = enemy_spawner_8.position
			9:
				enemy.position = enemy_spawner_9.position
			10:
				enemy.position = enemy_spawner_10.position
			11:
				enemy.position = enemy_spawner_11.position
			12:
				enemy.position = enemy_spawner_12.position
			13:
				enemy.position = enemy_spawner_13.position
			14:
				enemy.position = exit.position
		add_child(enemy)
		
func instance_enemy2():
	var enemies_count = randi_range(maxi(1, player_data.levels), maxi(3, player_data.levels*4))
	for i in range(enemies_count):
		var enemy = enemy2_scene.instantiate()
		
		var spawn_point = randi_range(1,14)
		match spawn_point:
			1:
				enemy.position = enemy_spawner_1.position
			2:
				enemy.position = enemy_spawner_2.position
			3:
				enemy.position = enemy_spawner_3.position
			4:
				enemy.position = enemy_spawner_4.position
			5:
				enemy.position = enemy_spawner_5.position
			6:
				enemy.position = enemy_spawner_6.position
			7:
				enemy.position = enemy_spawner_7.position
			8:
				enemy.position = enemy_spawner_8.position
			7:
				enemy.position = enemy_spawner_8.position
			9:
				enemy.position = enemy_spawner_9.position
			10:
				enemy.position = enemy_spawner_10.position
			11:
				enemy.position = enemy_spawner_11.position
			12:
				enemy.position = enemy_spawner_12.position
			13:
				enemy.position = enemy_spawner_13.position
			14:
				enemy.position = exit.position
		add_child(enemy)
		
func instance_enemy3():
	var enemies_count = randi_range(maxi(1, player_data.levels), maxi(5, player_data.levels*2))
	for i in range(enemies_count):
		var enemy = enemy3_scene.instantiate()
		
		var spawn_point = randi_range(1,14)
		match spawn_point:
			1:
				enemy.position = enemy_spawner_1.position
			2:
				enemy.position = enemy_spawner_2.position
			3:
				enemy.position = enemy_spawner_3.position
			4:
				enemy.position = enemy_spawner_4.position
			5:
				enemy.position = enemy_spawner_5.position
			6:
				enemy.position = enemy_spawner_6.position
			7:
				enemy.position = enemy_spawner_7.position
			8:
				enemy.position = enemy_spawner_8.position
			7:
				enemy.position = enemy_spawner_8.position
			9:
				enemy.position = enemy_spawner_9.position
			10:
				enemy.position = enemy_spawner_10.position
			11:
				enemy.position = enemy_spawner_11.position
			12:
				enemy.position = enemy_spawner_12.position
			13:
				enemy.position = enemy_spawner_13.position
			14:
				enemy.position = exit.position
		add_child(enemy)
		
func instance_enemy4():
	var enemies_count = randi_range(maxi(1, player_data.levels), maxi(4, player_data.levels*3))
	for i in range(enemies_count):
		var enemy = enemy4_scene.instantiate()
		
		var spawn_point = randi_range(1,14)
		match spawn_point:
			1:
				enemy.position = enemy_spawner_1.position
			2:
				enemy.position = enemy_spawner_2.position
			3:
				enemy.position = enemy_spawner_3.position
			4:
				enemy.position = enemy_spawner_4.position
			5:
				enemy.position = enemy_spawner_5.position
			6:
				enemy.position = enemy_spawner_6.position
			7:
				enemy.position = enemy_spawner_7.position
			8:
				enemy.position = enemy_spawner_8.position
			7:
				enemy.position = enemy_spawner_8.position
			9:
				enemy.position = enemy_spawner_9.position
			10:
				enemy.position = enemy_spawner_10.position
			11:
				enemy.position = enemy_spawner_11.position
			12:
				enemy.position = enemy_spawner_12.position
			13:
				enemy.position = enemy_spawner_13.position
			14:
				enemy.position = exit.position
		add_child(enemy)

func instance_silverspikes():
	var silverspikes_count = randi_range(3*player_data.levels,8)
	for i in range(silverspikes_count):
		var silverspikes = silverspikes_scene.instantiate()
		add_child(silverspikes)
		
func instance_redspikes():
	var redspikes_count = randi_range(2*player_data.levels,12)
	for i in range(redspikes_count):
		var redspikes = redspikes_scene.instantiate()
		add_child(redspikes)

func _on_timer_timeout():
	player_data.toggle_loading_screen = true
	player_data.levels = 0 #set back to 0
	player_data.sound_selecter = 0
	player_data.hurt_ready = true

func _on_next_level_timer_timeout():
	intermission_level.visible = true
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

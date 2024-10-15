extends Node2D

#region imports
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
@onready var spawner_1 = $enemy_spawner1
@onready var spawner_2 = $enemy_spawner2
@onready var spawner_3 = $enemy_spawner3
@onready var spawner_4 = $enemy_spawner4
@onready var spawner_5 = $enemy_spawner5
@onready var spawner_6 = $enemy_spawner6
@onready var spawner_7 = $enemy_spawner7
@onready var spawner_8 = $enemy_spawner8
@onready var spawner_9 = $enemy_spawner9
@onready var spawner_10 = $enemy_spawner10
@onready var spawner_11 = $enemy_spawner11
@onready var spawner_12 = $enemy_spawner12
@onready var spawner_13 = $enemy_spawner13
@onready var spawner_14 = $enemy_spawner14
@onready var spawner_15 = $enemy_spawner15
@onready var spawner_16 = $enemy_spawner16
@onready var spawner_17 = $enemy_spawner17
@onready var spawner_18 = $enemy_spawner18
@onready var spawner_19 = $enemy_spawner19
@onready var spawner_20 = $enemy_spawner20
@onready var spawner_21 = $enemy_spawner21
@onready var spawner_22 = $enemy_spawner22
@onready var spawner_23 = $enemy_spawner23
@onready var spawner_24 = $enemy_spawner24
@onready var spawner_25 = $enemy_spawner25
@onready var spawner_26 = $enemy_spawner26
@onready var spawner_27 = $enemy_spawner27
@onready var spawner_28 = $enemy_spawner28
@onready var spawner_29 = $enemy_spawner29
@onready var spawner_30 = $enemy_spawner30
@onready var spawner_31 = $enemy_spawner31
@onready var spawner_32 = $enemy_spawner32
@onready var spawner_33 = $enemy_spawner33
@onready var spawner_34 = $enemy_spawner34
@onready var spawner_35 = $enemy_spawner35

@onready var exit = $exit

@onready var main_mouse_icon = $CanvasLayer/main_mouse_icon
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var pause_menu_canvas = $CanvasLayer
#endregion

@onready var loading_screen_canvas = $CanvasLayer2
@onready var loading_screen_intermission = $CanvasLayer2/loading_screen_intermission

@onready var tilemap = $TileMap3

var enemies_array
var spikes_array
var spike
var change_scenes_once = 0

# Called when the node enters the scene tree for the first time.
func _ready():
#region New Code Region
	enemies_array = [spawner_1, 
		spawner_2, 
		spawner_3,
		spawner_4, 
		spawner_5,
		spawner_6, 
		spawner_7,
		spawner_8, 
		spawner_9,
		spawner_10, 
		spawner_11,
		spawner_12,
		spawner_13,
		spawner_14,
		spawner_15,
		spawner_16,
		spawner_17,
		spawner_18,
		spawner_19,
		spawner_20,
		spawner_21,
		spawner_22,
		spawner_23,
		spawner_24,
		spawner_25,
		spawner_26,
		spawner_27,
		spawner_28,
		spawner_29,
		spawner_30,
		spawner_31,
		spawner_32,
		spawner_33,
		spawner_34,
		spawner_35
	]
	
	spikes_array = [spawner_1, 
		spawner_2, 
		spawner_3,
		spawner_4, 
		spawner_5,
		spawner_6, 
		spawner_7,
		spawner_8, 
		spawner_9,
		spawner_10, 
		spawner_11,
		spawner_12,
		spawner_13,
		spawner_14,
		spawner_15,
		spawner_16,
		spawner_17,
		spawner_18,
		spawner_19,
		spawner_20,
		spawner_21,
		spawner_22,
		spawner_23,
		spawner_24,
		spawner_25,
		spawner_26,
		spawner_27,
		spawner_28,
		spawner_29,
		spawner_30,
		spawner_31,
		spawner_32,
		spawner_33,
		spawner_34,
		spawner_35
	]
#endregion
	
	player_data.game_active = true
	player_data.levels = 21
	player_data.hurt_ready = true
	player_data.reached_exit = false
	generate_level()
		
	ThemePlayer.theme_grand_stop()
	ThemePlayer.theme_magma_stop()
	ThemePlayer.theme_skytowersummit()
	ThemePlayer.theme_makuhita_stop()
	ThemePlayer.theme_silentchasm_stop()
	ThemePlayer.theme_steel_stop()
	ThemePlayer.theme_lapis_stop()
	ThemePlayer.theme_sinister_stop()
	ThemePlayer.theme_blazepeak_stop()
	ThemePlayer.theme_sinister_stop()
	
	pause_menu.exit_pause_menu.connect(on_exit_pause_menu)
	pause_menu.enter_pause_menu.connect(on_enter_pause_menu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player_data.player_is_dead:
		loading_screen_intermission.reset_next_scene()
		
	if player_data.toggle_loading_screen:
		intermission_level.visible = false
		gui.visible = false
		pause_menu.visible = false
		if loading_screen_canvas.layer < 4:
			loading_screen_canvas.layer = 4
			loading_screen_canvas.visible = true
			loading_screen_intermission.visible = true
			loading_screen_intermission.z_index = 10

		if change_scenes_once == 0:
			if player_data.player_is_dead:
				loading_screen_intermission.reset_next_scene()
			else:
				loading_screen_intermission.load_next_scene()
			$next_level_timer.start()
			change_scenes_once += 1
			player_data.toggle_loading_screen = false
	
	ThemePlayer.theme_questionairre_stop()
	ThemePlayer.theme_fileselect_stop()
	ThemePlayer.theme_ninetales_stop()


func generate_level():
	instance_player()
		
	instance_enemy_at_spawn()
	
	instance_redspikes()


func _on_next_level_timer_timeout():
	intermission_level.visible = true
	gui.visible = true
	pause_menu.visible = true
	loading_screen_canvas.layer = -10
	loading_screen_canvas.visible = false
	loading_screen_intermission.visible = false
	loading_screen_intermission.z_index = -10
	player_data.toggle_loading_screen = false
	change_scenes_once = 0
	
func instance_player():
	var player = player_scene.instantiate()
	add_child(player)
	player.position = player_spawn.position

func instance_enemy_at_spawn():
	for i in range(20):
		var enemy_type = randi_range(1,4)
		var enemy
		match enemy_type:
			1:
				enemy = enemy1_scene.instantiate()
			2:
				enemy = enemy2_scene.instantiate()
			3:
				enemy = enemy3_scene.instantiate()
			4:
				enemy = enemy4_scene.instantiate()
		enemy.position = exit.position
		add_child(enemy)
		add_child(enemy)
		add_child(enemy)
				
	
func instance_enemy1():
	var enemies_count = randi_range(maxi(1, player_data.levels), maxi(2, player_data.levels*5))
	for i in range(enemies_count):
		var enemy = enemy1_scene.instantiate()
		choose_spawn_point(enemy)
		add_child(enemy)
		
func choose_spawn_point(enemy):
	var spawn_point = randi_range(1,36)
	match spawn_point:
		1:
			enemy.position = spawner_1.position
		2:
			enemy.position = spawner_2.position
		3:
			enemy.position = spawner_3.position
		4:
			enemy.position = spawner_4.position
		5:
			enemy.position = spawner_5.position
		6:
			enemy.position = spawner_6.position
		7:
			enemy.position = spawner_7.position
		8:
			enemy.position = spawner_8.position
		7:
			enemy.position = spawner_8.position
		9:
			enemy.position = spawner_9.position
		10:
			enemy.position = spawner_10.position
		11:
			enemy.position = spawner_11.position
		12:
			enemy.position = spawner_12.position
		13:
			enemy.position = spawner_13.position
		14:
			enemy.position = spawner_14.position
		15:
			enemy.position = spawner_15.position
		16:
			enemy.position = spawner_16.position
		17:
			enemy.position = spawner_17.position
		18:
			enemy.position = spawner_18.position
		19:
			enemy.position = spawner_19.position
		20:
			enemy.position = spawner_20.position
		21:
			enemy.position = spawner_21.position
		22:
			enemy.position = spawner_22.position
		23:
			enemy.position = spawner_23.position
		24:
			enemy.position = spawner_24.position
		25:
			enemy.position = spawner_25.position
		26:
			enemy.position = spawner_26.position
		27:
			enemy.position = spawner_27.position
		28:
			enemy.position = spawner_28.position
		29:
			enemy.position = spawner_29.position
		30:
			enemy.position = spawner_30.position
		31:
			enemy.position = spawner_31.position
		32:
			enemy.position = spawner_32.position
		33:
			enemy.position = spawner_33.position
		34:
			enemy.position = spawner_34.position
		35:
			enemy.position = spawner_35.position
		36:
			enemy.position = exit.position
			
func instance_enemy2():
	var enemies_count = randi_range(maxi(1, player_data.levels), maxi(3, player_data.levels*4))
	for i in range(enemies_count):
		var enemy = enemy2_scene.instantiate()
		choose_spawn_point(enemy)
		add_child(enemy)
		
func instance_enemy3():
	var enemies_count = randi_range(maxi(1, player_data.levels), maxi(5, player_data.levels*2))
	for i in range(enemies_count):
		var enemy = enemy3_scene.instantiate()
		choose_spawn_point(enemy)
		add_child(enemy)
		
func instance_enemy4():
	var enemies_count = randi_range(maxi(1, player_data.levels), maxi(4, player_data.levels*3))
	for i in range(enemies_count):
		var enemy = enemy4_scene.instantiate()
		choose_spawn_point(enemy)
		add_child(enemy)

func instance_silverspikes():
	var silverspikes_count = randi_range(3*player_data.levels,8)
	for i in range(silverspikes_count):
		var silverspikes = silverspikes_scene.instantiate()
		add_child(silverspikes)
		
func instance_redspikes():
	var redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_1.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_2.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_3.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_4.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_5.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_6.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_7.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_8.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_9.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_10.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_11.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_12.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_13.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_14.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_15.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_16.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_17.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_18.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_19.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_20.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_21.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_22.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_23.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_24.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_25.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_26.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_27.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_28.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_29.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_30.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_31.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_32.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_33.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_34.position
	add_child(redspikes)
	redspikes = redspikes_scene.instantiate()
	redspikes.position = spawner_35.position
	add_child(redspikes)
	
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
	
func _on_enemy_spawn_timeout():
	var enemy
	var enemy_type = randi_range(0, 3)
	var enemy_position
	match enemy_type:
		0:
			enemy = enemy1_scene.instantiate()
			for i in range(12):
				enemy_position = enemies_array.pick_random()
				enemy.position = enemy_position.position
				add_child(enemy)
		1:
			enemy = enemy2_scene.instantiate()
			for i in range(10):
				enemy_position = enemies_array.pick_random()
				enemy.position = enemy_position.position
				add_child(enemy)
		2:
			enemy = enemy3_scene.instantiate()
			for i in range(6):
				enemy_position = enemies_array.pick_random()
				enemy.position = enemy_position.position
				add_child(enemy)
		3:
			enemy = enemy4_scene.instantiate()
			for i in range(8):
				enemy_position = enemies_array.pick_random()
				enemy.position = enemy_position.position
				add_child(enemy)
	$enemy_spawn.start()

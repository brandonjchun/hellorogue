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

@onready var exit = $exit

@onready var main_mouse_icon = $CanvasLayer/main_mouse_icon
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var pause_menu_canvas = $CanvasLayer


@onready var loading_screen_canvas = $CanvasLayer2
@onready var loading_screen_intermission = $CanvasLayer2/loading_screen_intermission
@onready var next_level_timer = $next_level_timer

@onready var tilemap = $TileMap3

var enemies_array 
var spikes_array
var spike
var ground_layer = 0
var change_scenes_once = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	
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
		spawner_30
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
		spawner_30
	]
	
	player_data.game_active = true
	player_data.levels = 20
	player_data.hurt_ready = true
	player_data.reached_exit = false
	generate_level()
	
	ThemePlayer.theme_grand_stop()
	ThemePlayer.theme_magma()
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
			next_level_timer.start()
			change_scenes_once += 1
			player_data.toggle_loading_screen = false
	
	ThemePlayer.theme_questionairre_stop()
	ThemePlayer.theme_fileselect_stop()
	ThemePlayer.theme_ninetales_stop()

func generate_level():
	instance_player()
		
	instance_enemy_at_spawn()

func instance_player():
	var player = player_scene.instantiate()
	add_child(player)
	player.position = player_spawn.position

func instance_enemy_at_spawn():
	for i in range(40):
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

func instance_silverspikes():
	var silverspikes_count = randi_range(3*player_data.levels,8)
	for i in range(silverspikes_count):
		var silverspikes = silverspikes_scene.instantiate()
		add_child(silverspikes)
		
func _on_spikes_timer_timeout():
	if spikes_array.size()-3 >= 1:
		var spike_type = randi_range(0, 1)
		var spike_position_source = randi_range(0, spikes_array.size()-3)
		var spike_source = spikes_array.pop_at(spike_position_source)
		match spike_type:
			0: 
				spike = silverspikes_scene.instantiate()
			1: 
				spike = redspikes_scene.instantiate()
		spike.position = spike_source.position
		spikes_array.remove_at(spike_position_source)
		add_child(spike)
	
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
	
func _on_enemy_spawn_timeout():
	var enemy
	var enemy_type = randi_range(0, 3)
	var enemy_position
	match enemy_type:
		0:
			enemy = enemy1_scene.instantiate()
			for i in range(10):
				enemy_position = enemies_array.pick_random()
				enemy.position = enemy_position.position
				add_child(enemy)
		1:
			enemy = enemy2_scene.instantiate()
			for i in range(8):
				enemy_position = enemies_array.pick_random()
				enemy.position = enemy_position.position
				add_child(enemy)
		2:
			enemy = enemy3_scene.instantiate()
			for i in range(4):
				enemy_position = enemies_array.pick_random()
				enemy.position = enemy_position.position
				add_child(enemy)
		3:
			enemy = enemy4_scene.instantiate()
			for i in range(6):
				enemy_position = enemies_array.pick_random()
				enemy.position = enemy_position.position
				add_child(enemy)
	$enemy_spawn.start()

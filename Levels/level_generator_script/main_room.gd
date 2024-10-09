extends Node2D

@onready var player_scene = preload("res://Entities/Scenes/Player/player.tscn")
@onready var exit_scene = preload("res://interactables/scenes/exit.tscn")
@onready var enemy1_scene = preload("res://Entities/Scenes/Enemies/enemy_1.tscn")
@onready var enemy2_scene = preload("res://Entities/Scenes/Enemies/enemy_2.tscn")
@onready var silverspikes_scene = preload("res://interactables/scenes/dead_area.tscn")
@onready var redspikes_scene = preload("res://interactables/scenes/redspikes.tscn")
@onready var menu_scene = preload("res://Levels/menu.tscn")
@onready var main_level = $"."
@onready var gui = $GUI

var lev = player_data.levels
@onready var pause_menu_canvas = $pause_menu
@onready var pause_menu = $pause_menu/PauseMenu
@onready var loading_screen_canvas = $loading_screen_canvas
@onready var loading_screen = $loading_screen_canvas/loading_screen

@onready var tilemap = $TileMap
@export var borders = Rect2(1, 1, 200 + lev*2, 100 + lev*2)
var walker
var map
var ground_layer = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	generate_level()
	if player_data.levels >= 0 and player_data.levels < 3:
		player_data.sound_selecter = 0
	if player_data.levels >= 3 and player_data.levels < 6:
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
	if player_data.levels >= 21 and player_data.levels < 24:
		player_data.sound_selecter = 7
		
	match player_data.sound_selecter:
		0:
			$wizards.play()
		1:
			$mercury.play()
		2:
			$mars.play()
		3:
			$mapbasic.play()
		4:
			$goodfight.play()
		5:
			$sinister.play()
		6:
			$plumus.play()
		7:
			$final.play()
			

func generate_level():
	walker = Walker_room.new(Vector2(3 + floor(lev/3), 5 + floor(lev/3)), borders)
	map = walker.walk(2400)
	
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
	if player_data.levels >= 6:
		instance_enemy2()
	if player_data.levels >= 9:
		instance_redspikes()
		
func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		if pause_menu_canvas.layer != 3:
			pause_menu_canvas.layer = 3
		else:
			pause_menu_canvas.layer = -3
		
func instance_player():
	var player = player_scene.instantiate()
	add_child(player)
	#was map.pop_front()
	player.position = map[randi_range(0, 12)] * 16
	
func instance_exit():
	var exit = exit_scene.instantiate()
	add_child(exit)
	exit.position = walker.get_end_room().position * 16

func instance_enemy1():
	var enemies_count = randi_range(player_data.levels, player_data.levels*2)
	for i in range(enemies_count):
		var enemy = enemy1_scene.instantiate()
		enemy.position = (map.pick_random() * borders.position) * 16
		add_child(enemy)
		
func instance_enemy2():
	var enemies_count = randi_range(player_data.levels, player_data.levels*3)
	for i in range(enemies_count):
		var enemy = enemy2_scene.instantiate()
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
	main_level.visible = false
	gui.visible = false
	pause_menu.visible = false
	player_data.levels += 1 #set back to 0
	player_data.sound_selecter = 0
	if loading_screen_canvas.layer < 4:
		loading_screen_canvas.layer = 4
		loading_screen_canvas.visible = true
		loading_screen.visible = true
		loading_screen.z_index = 10
	loading_screen.load_next_scene()
	$next_level_timer.start()
	

func _on_next_level_timer_timeout():
	main_level.visible = true
	gui.visible = true
	pause_menu.visible = true
	loading_screen_canvas.layer = -2
	loading_screen_canvas.visible = false
	loading_screen.visible = false
	loading_screen.z_index = -2

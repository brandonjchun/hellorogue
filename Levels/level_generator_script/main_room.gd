extends Node2D

@onready var player_scene = preload("res://Entities/Scenes/Player/player.tscn")
@onready var exit_scene = preload("res://interactables/scenes/exit.tscn")
@onready var enemy1_scene = preload("res://Entities/Scenes/Enemies/enemy_1.tscn")
@onready var enemy2_scene = preload("res://Entities/Scenes/Enemies/enemy_2.tscn")
@onready var silverspikes_scene = preload("res://interactables/scenes/dead_area.tscn")
@onready var redspikes_scene = preload("res://interactables/scenes/redspikes.tscn")
@onready var menu_scene = preload("res://Levels/menu.tscn")
@onready var tilemap = $TileMap
@export var borders = Rect2(1, 1, 200, 100)
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
		
	match player_data.sound_selecter:
		0:
			$mapbasic.play()
		1:
			$mars.play()
		2:
			$mercury.play()
		3:
			$goodfight.play()
		4:
			$venus.play()
		5:
			$bossmain.play()
		6:
			$plumus.play()

func generate_level():
	walker = Walker_room.new(Vector2(6, 10), borders)
	map = walker.walk(600)
	
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
		instance_enemy2()
	if player_data.levels >= 6:
		instance_enemy2()
	instance_spikes()
	
func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		instance_menu()
		
		
func instance_player():
	var player = player_scene.instantiate()
	add_child(player)
	player.position = map.pop_front() * 16
	
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

func instance_spikes():
	var silverspikes_count = randi_range(3*player_data.levels,8)
	for i in range(silverspikes_count):
		var silverspikes = silverspikes_scene.instantiate()
		silverspikes.position = (map.pick_random() * borders.position) * 16
		add_child(silverspikes)
		
	var redspikes_count = randi_range(2*player_data.levels,12)
	for i in range(redspikes_count):
		var redspikes = redspikes_scene.instantiate()
		redspikes.position = (map.pick_random() * borders.position) * 16
		add_child(redspikes)

func instance_menu():
	var menu = menu_scene.instantiate()
	add_child(menu)

func _on_timer_timeout():
	player_data.levels = 0
	player_data.sound_selecter = 0
	get_tree().reload_current_scene()
	


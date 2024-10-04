extends Node2D

@onready var tilemap = $TileMap
@export var borders = Rect2(1, 1, 500, 300)
var walker
var map

var ground_layer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	generate_level()

func generate_level():
	walker = Walker_room.new(Vector2(6, 10), borders)
	map = walker.walk(3000)
	
	var using_cells: Array = []
	var all_cells: Array = tilemap.get_used_cells(ground_layer)
	tilemap.clear()
	walker.queue_free()
	
	for tile in all_cells:
		if !map.has(Vector2(tile.x, tile.y)):
			using_cells.append(tile)
			
	tilemap.set_cells_terrain_connect(ground_layer, using_cells, ground_layer, ground_layer, false)
	tilemap.set_cells_terrain_path(ground_layer, using_cells, ground_layer, ground_layer, false)
	
func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()

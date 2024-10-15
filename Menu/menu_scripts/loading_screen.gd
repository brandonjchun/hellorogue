extends Control

var next_scene = "res://Levels/main_level.tscn"
# Called when the node enters the scene tree for the first time.
func _ready():
		ResourceLoader.load_threaded_request(next_scene)
	
	
func load_next_scene():
		ResourceLoader.load_threaded_request(next_scene)
	
func reset_player_data_states():
	player_data.health = 24
	player_data.ammo = 50
	player_data.levels = 1
	player_data.sound_selecter = 0
	player_data.hurt_ready = true
	player_data.intermission_levels = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var progress = []
	ResourceLoader.load_threaded_get_status(next_scene, progress)
	$progress_bar.value = progress[0] * 100
	
	if progress[0] == 1:
		var packed_scene = ResourceLoader.load_threaded_get(next_scene)
		get_tree().change_scene_to_packed(packed_scene)


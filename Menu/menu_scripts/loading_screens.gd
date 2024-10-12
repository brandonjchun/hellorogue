extends Control

var next_scene = "res://Levels/main_level.tscn"
@onready var anim = $anim

func load_next_scene():
	if player_data.intermission_levels:
		next_scene = "res://Levels/intermission_level_2.tscn"
		player_data.levels = 19
	anim.play("fly")
	ResourceLoader.load_threaded_request(next_scene)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var progress = []
	ResourceLoader.load_threaded_get_status(next_scene, progress)
	$progress_bar.value = progress[0] * 100
	
	if progress[0] == 1:
		var packed_scene = ResourceLoader.load_threaded_get(next_scene)
		get_tree().change_scene_to_packed(packed_scene)

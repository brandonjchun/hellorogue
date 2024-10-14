extends Control

func load_next_scene():
	if player_data.next_scene == "res://Levels/intermission_level.tscn":
		player_data.next_scene = "res://Levels/intermission_level_2.tscn"
	elif player_data.next_scene == "res://Levels/intermission_level_2.tscn":
		player_data.next_scene = "res://Levels/intermission_level_1.tscn"
	$anim.play("fly")
	ResourceLoader.load_threaded_request(player_data.next_scene)

func reset_next_scene():
	player_data.next_scene = "res://Levels/intermission_level.tscn"
	ResourceLoader.load_threaded_request(player_data.next_scene)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var progress = []
	ResourceLoader.load_threaded_get_status(player_data.next_scene, progress)
	$progress_bar.value = progress[0] * 100
	
	if progress[0] == 1:
		var packed_scene = ResourceLoader.load_threaded_get(player_data.next_scene)
		get_tree().change_scene_to_packed(packed_scene)

extends Control
	
func load_next_scene():
	if PlayerData.reset_button_hit:
		PlayerData.next_scene = "res://Levels/intermission_level.tscn"
		PlayerData.reset_button_hit = false
	elif PlayerData.next_scene == "res://Levels/intermission_level.tscn":
		PlayerData.next_scene = "res://Levels/intermission_level_2.tscn"
	elif PlayerData.next_scene == "res://Levels/intermission_level_2.tscn":
		PlayerData.next_scene = "res://Levels/intermission_level_1.tscn"
	elif PlayerData.next_scene == "res://Levels/intermission_level_1.tscn":
		PlayerData.next_scene = "res://Levels/final_level.tscn"
	$anim.play("fly")
	ResourceLoader.load_threaded_request(PlayerData.next_scene)

func reset_next_scene():
	PlayerData.next_scene = "res://Levels/intermission_level.tscn"
	ResourceLoader.load_threaded_request(PlayerData.next_scene)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var progress = []
	ResourceLoader.load_threaded_get_status(PlayerData.next_scene, progress)
	$progress_bar.value = progress[0] * 100
	
	if progress[0] == 1:
		var packed_scene = ResourceLoader.load_threaded_get(PlayerData.next_scene)
		get_tree().change_scene_to_packed(packed_scene)

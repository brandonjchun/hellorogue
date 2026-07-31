extends Control

var next_scene = "res://Levels/main_level.tscn"

func _ready():
	# This is the screen a new run starts on, so it is where run state gets put
	# back. reset_player_data_states() used to live here for exactly this
	# purpose but was never called from anywhere, which is how the 9000 HP debug
	# value and the sticky final_level flag survived into normal play.
	PlayerData.reset_run()
	ResourceLoader.load_threaded_request(next_scene)

func load_next_scene():
	ResourceLoader.load_threaded_request(next_scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var progress = []
	ResourceLoader.load_threaded_get_status(next_scene, progress)
	$progress_bar.value = progress[0] * 100

	if progress[0] == 1:
		var packed_scene = ResourceLoader.load_threaded_get(next_scene)
		get_tree().change_scene_to_packed(packed_scene)

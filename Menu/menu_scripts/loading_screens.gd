extends Control

var next_scene = "res://Levels/main_level.tscn"

func _ready():
	$anim.play("jumping")
	
func load_intermission():
	ResourceLoader.load_threaded_request("res://Levels/intermission_level_1.tscn")
func load_next_scene():
	ResourceLoader.load_threaded_request(next_scene)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var progress = []
	ResourceLoader.load_threaded_get_status(next_scene, progress)
	$progress_bar.value = progress[0] * 100
	
	if progress[0] == 1:
		var packed_scene = ResourceLoader.load_threaded_get(next_scene)
		get_tree().change_scene_to_packed(packed_scene)

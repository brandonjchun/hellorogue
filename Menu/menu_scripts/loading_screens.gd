extends Control

# The procedural floors' loading screen. main_room gates this behind its own
# `loading_screen_timer`, so the minimum-display hold lives there rather than
# here; what this needs is the arm guard, so it does not poll a scene path
# nobody has requested.

var next_scene = "res://Levels/main_level.tscn"
@onready var anim = $anim

var _armed := false

func load_next_scene():
	# Reset, from the pause menu.
	#
	# This flag used to be read only by loading_screen_intermission, so on the
	# procedural floors -- which route through this script -- Reset did nothing
	# but reload the next floor with the run intact: same level counter, same
	# health, same bank, same purchases. main_room then cleared the flag unread.
	if PlayerData.reset_button_hit:
		PlayerData.reset_button_hit = false
		PlayerData.reset_run()
		next_scene = "res://Levels/main_level.tscn"
	elif PlayerData.intermission_levels:
		next_scene = "res://Levels/intermission_level.tscn"
		PlayerData.levels = 19
	anim.play("fly")
	_armed = true
	ResourceLoader.load_threaded_request(next_scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not _armed:
		return

	var progress = []
	ResourceLoader.load_threaded_get_status(next_scene, progress)
	$progress_bar.value = progress[0] * 100

	if progress[0] == 1:
		var packed_scene = ResourceLoader.load_threaded_get(next_scene)
		_armed = false
		get_tree().change_scene_to_packed(packed_scene)

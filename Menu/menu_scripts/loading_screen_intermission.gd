extends Control

# The intermission chain's loading screen.
#
# _process used to poll unconditionally and swap the scene the instant the
# resource reported ready. Two things fell out of that:
#
#  * ArenaLevel fires reset_next_scene() the moment player_is_dead goes true --
#    while player.dead() is still on its two-second await. The load resolved a
#    few frames later and yanked the player out mid-death-animation.
#  * On a warm cache the load resolves on the same frame it was requested, so
#    the screen this node exists to show was never drawn at all.
#
# It now only polls once something has actually armed it, and holds for a
# minimum time so the transition reads as a transition. main_room does the same
# job with an authored `loading_screen_timer`; these scenes have no such node,
# so the hold is kept here.
const MIN_DISPLAY := 1.5

var _armed := false
var _elapsed := 0.0

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
	_arm()

func reset_next_scene():
	PlayerData.next_scene = "res://Levels/intermission_level.tscn"
	_arm()

# Requests the load and starts the clock. Idempotent, so a caller that fires
# twice -- ArenaLevel did, once off player_is_dead and once off
# toggle_loading_screen -- does not restart the hold.
func _arm() -> void:
	if _armed:
		return
	_armed = true
	_elapsed = 0.0
	ResourceLoader.load_threaded_request(PlayerData.next_scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not _armed:
		return
	_elapsed += delta

	var progress = []
	ResourceLoader.load_threaded_get_status(PlayerData.next_scene, progress)
	$progress_bar.value = progress[0] * 100

	if progress[0] == 1 and _elapsed >= MIN_DISPLAY:
		var packed_scene = ResourceLoader.load_threaded_get(PlayerData.next_scene)
		_armed = false
		get_tree().change_scene_to_packed(packed_scene)

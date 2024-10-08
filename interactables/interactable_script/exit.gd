extends Area2D

var touched_exit = false

func _on_body_entered(body):
	if body.name == "Player" and not touched_exit:
		player_data.levels += 1
		touched_exit = true
		$exit_sound.play()
		await get_tree().create_timer(1.25).timeout
		get_tree().reload_current_scene()
		

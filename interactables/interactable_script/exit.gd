extends Area2D



func _on_body_entered(body):
	if body.name == "Player" and not player_data.reached_exit:
		player_data.levels += 1
		player_data.reached_exit = true
		$exit_sound.play()
		await get_tree().create_timer(1.25).timeout
		get_tree().reload_current_scene()
		player_data.reached_exit = false
		

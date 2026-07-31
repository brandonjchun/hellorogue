extends Area2D

func _on_body_entered(body):
	if body.name == "Player" and not PlayerData.reached_exit:
		PlayerData.levels += 1
		if PlayerData.levels >= 19:
			PlayerData.intermission_levels = true
		PlayerData.reached_exit = true
		PlayerData.hurt_ready = false
		$exit_sound.play()
		await get_tree().create_timer(1.25).timeout
		PlayerData.toggle_loading_screen = true
		
		

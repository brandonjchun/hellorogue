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
		# Banking the leftover seconds is the level's job -- only it can see the
		# clock -- and it has already done it by now, off reached_exit. All this
		# has to decide is whether the shop gets a turn before the loading
		# screen. When it does, the shop is what sets toggle_loading_screen.
		if PlayerData.shop_due():
			PlayerData.shop_pending = true
		else:
			PlayerData.toggle_loading_screen = true
		
		

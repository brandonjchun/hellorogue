extends Area2D

@export var ammo = 10

func _on_body_entered(body):
	$ammopickup.play()
	if body.name == "Player":
		player_data.ammo += ammo
		queue_free()

func _on_timer_timeout():
	queue_free()

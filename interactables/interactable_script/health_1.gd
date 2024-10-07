extends Area2D

@export var health = 1

func _on_body_entered(body):
	if body.name == "Player":
		player_data.health += health
		queue_free()

func _on_timer_timeout():
	queue_free()

extends Area2D

func remove_trail():
	queue_free()
	
func _on_timer_timeout():
	remove_trail()

extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready():
	$melee_sound.play()
	$anim.play("slash")
	$melee_timer.start()
	
func _on_timer_timeout():
	queue_free()
	

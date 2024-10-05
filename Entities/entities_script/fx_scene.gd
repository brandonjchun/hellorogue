extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$anim.play("explode")
	await get_tree().create_timer(0.6).timeout
	queue_free()

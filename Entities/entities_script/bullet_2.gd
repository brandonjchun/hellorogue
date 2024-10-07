extends Area2D

@onready var anim = $anim

# Called when the node enters the scene tree for the first time.
func _ready():
	$anim.play("attack")
	$bullet2_timer.start()
	
func _on_timer_timeout():
	pass
	
	

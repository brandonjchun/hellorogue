extends Area2D

@export var speed = 75
var direction = Vector2.RIGHT

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(direction * speed * delta)

func _on_body_entered(body):
	queue_free()

func _on_visible_screen_exited():
	queue_free()

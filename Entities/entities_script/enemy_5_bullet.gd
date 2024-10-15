extends Area2D

@export var speed = 60
var direction = Vector2.RIGHT


# Called when the node enters the scene tree for the first time.
func _ready():
	$anim.play("attack")
	var play_sound = randi_range(1, 500)
	if play_sound == 1:
		$bullet_sound.play()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(direction * speed * delta)

func _on_body_entered(body):
	queue_free()

func _on_timer_timeout():
	queue_free()

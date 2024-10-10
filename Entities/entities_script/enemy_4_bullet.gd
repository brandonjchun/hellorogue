extends Area2D

@export var speed = 1.25
var direction = Vector2.RIGHT

# Called when the node enters the scene tree for the first time.
func _ready():
	$bullet_sound.play()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(direction * speed * delta)

func _on_visible_screen_exited():
	queue_free()
	
func _on_body_entered(body):
	queue_free()
	
func _on_area_entered(area):
	if area.is_in_group("Bullet"):
		queue_free()


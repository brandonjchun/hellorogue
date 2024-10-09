extends Area2D

@export var speed = 1
var direction = Vector2.RIGHT
# Called when the node enters the scene tree for the first time.
func _ready():
	if player_data.degrees_to_player >= 9.5 and player_data.degrees_to_player < 50.0:
		$anim.play("fl")
	if player_data.degrees_to_player >= -50.0 and player_data.degrees_to_player < -12.0:
		$anim.play("fu")
	if player_data.degrees_to_player >= -12.0 and player_data.degrees_to_player < 2.0:
		$anim.play("fr")
	if player_data.degrees_to_player >= 2.0 and player_data.degrees_to_player < 9.5:
		$anim.play("fd")
	$fire_sound.play()
	
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

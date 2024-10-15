extends Area2D

@export var speed = 75
var direction = Vector2.RIGHT

var sfx_finished = false
var was_body_entered = false
var was_area_entered = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$bullet_sound.finished.connect(_on_bullet_sound_finished)
	if player_data.degrees_to_player >= 9.5 and player_data.degrees_to_player < 50.0:
		$anim.play("fl")
	if player_data.degrees_to_player >= -50.0 and player_data.degrees_to_player < -12.0:
		$anim.play("fu")
	if player_data.degrees_to_player >= -12.0 and player_data.degrees_to_player < 2.0:
		$anim.play("fr")
	if player_data.degrees_to_player >= 2.0 and player_data.degrees_to_player < 9.5:
		$anim.play("fd")
	$bullet_sound.play()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if sfx_finished and (was_body_entered or was_area_entered):
		queue_free()
	translate(direction * speed * delta)

func _on_body_entered(body):
	if was_body_entered == false:
		hide()
		$CollisionShape2D.set_deferred("disabled", true)
		if sfx_finished:
			queue_free()
		else:
			was_body_entered = true
	
func _on_area_entered(area):
	if area.is_in_group("Bullet"):
		if was_body_entered == false:
			$CollisionShape2D.set_deferred("disabled", true)
			hide()
			if sfx_finished:
				queue_free()
			else:
				was_area_entered = true
				
func _on_bullet_sound_finished():
	sfx_finished = true

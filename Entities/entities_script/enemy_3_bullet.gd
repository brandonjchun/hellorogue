extends Area2D

@export var speed = 75
var direction = Vector2.RIGHT

var sfx_finished = false
var was_body_entered = false
var was_area_entered = false

# Called when the node enters the scene tree for the first time.
# Projectiles used to be parented to get_tree().root -- a sibling of the level
# scene rather than part of it -- so a scene change never freed them and any shot
# that missed everything flew on forever, accumulating for the whole session.
# They are parented to the level now (Globals.spawn_transient), which ends the
# cross-floor leak; this stays as the within-floor backstop, since a shot that
# hits nothing still has no other reason to stop.
const MAX_LIFETIME := 6.0

func _ready():
	get_tree().create_timer(MAX_LIFETIME).timeout.connect(queue_free)
	$bullet_sound.finished.connect(_on_bullet_sound_finished)
	_play_facing()
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

# Picks the flight animation from the bearing enemy_3 recorded when it fired.
#
# The four tests here used to read 9.5 / -12 / 2 / -50 -- thresholds with no
# geometric meaning, fitted around enemy_3 computing the angle *between two
# position vectors at the world origin* instead of the bearing to the player.
# With that fixed the value is a real -180..180 bearing, so these are the four
# quadrants: Godot's y axis points down, so positive is downward.
func _play_facing() -> void:
	var bearing: float = PlayerData.degrees_to_player
	if bearing >= -45.0 and bearing < 45.0:
		$anim.play("fr")
	elif bearing >= 45.0 and bearing < 135.0:
		$anim.play("fd")
	elif bearing >= -135.0 and bearing < -45.0:
		$anim.play("fu")
	else:
		$anim.play("fl")

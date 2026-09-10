extends Area2D

@export var speed = 90
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

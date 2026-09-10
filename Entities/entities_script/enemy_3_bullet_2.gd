extends Area2D

@export var speed = 131
var direction = Vector2.RIGHT
var boss_multiplier = 0


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
	ThemePlayer.play_e3_bullet()
	# The >= 400 test below was a second plain `if`, not an `elif`, so at full
	# boss health both ran and the >= 450 tier was overwritten on the same
	# frame it was chosen -- the slowest tier was unreachable.
	if PlayerData.boss_health >= 450:
		boss_multiplier = 0
	elif PlayerData.boss_health >= 400:
		boss_multiplier = 5
	elif PlayerData.boss_health >= 350:
		boss_multiplier = 10
	elif PlayerData.boss_health >= 300:
		boss_multiplier = 15
	elif PlayerData.boss_health >= 250:
		boss_multiplier = 20
	elif PlayerData.boss_health >= 200:
		boss_multiplier = 25
	elif PlayerData.boss_health >= 150:
		boss_multiplier = 30
	elif PlayerData.boss_health >= 100:
		boss_multiplier = 35
	else:
		boss_multiplier = 50
	speed += boss_multiplier
	_play_facing()
	$bullet_sound.play()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(direction * speed * delta)

func _on_body_entered(body):
	# Was gated on `PlayerData.hurt_ready`. The tilemap is a body too, so while
	# the player was in invulnerability frames these shots flew through walls.
	queue_free()

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

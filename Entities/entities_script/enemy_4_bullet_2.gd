extends Area2D

@export var speed = 157
var direction = Vector2.RIGHT

var boss_multiplier = 0

# Called when the node enters the scene tree for the first time.
# Projectiles are parented to get_tree().root, which is a sibling of the level
# scene rather than part of it -- so a scene change does not free them. Combined
# with only ever calling queue_free() on impact, any shot that missed everything
# flew on forever and accumulated for the whole session. This is the backstop.
const MAX_LIFETIME := 6.0

func _ready():
	get_tree().create_timer(MAX_LIFETIME).timeout.connect(queue_free)
	ThemePlayer.play_e4_bullet()
	# The >= 400 test below was a second plain `if`, not an `elif`, so at full
	# boss health both ran and the >= 450 tier was overwritten on the same
	# frame it was chosen -- the slowest tier was unreachable.
	if PlayerData.boss_health >= 450:
		boss_multiplier = 0
	elif PlayerData.boss_health >= 400:
		boss_multiplier = 10
	elif PlayerData.boss_health >= 350:
		boss_multiplier = 20
	elif PlayerData.boss_health >= 300:
		boss_multiplier = 30
	elif PlayerData.boss_health >= 250:
		boss_multiplier = 40
	elif PlayerData.boss_health >= 200:
		boss_multiplier = 50
	elif PlayerData.boss_health >= 150:
		boss_multiplier = 60
	elif PlayerData.boss_health >= 100:
		boss_multiplier = 70
	else:
		boss_multiplier = 80
	speed += boss_multiplier
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(direction * speed * delta)
	
func _on_body_entered(body):
	# Was gated on `PlayerData.hurt_ready`. The tilemap is a body too, so while
	# the player was in invulnerability frames these shots flew through walls.
	queue_free()

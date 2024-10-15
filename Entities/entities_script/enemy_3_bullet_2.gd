extends Area2D

@export var speed = 131
var direction = Vector2.RIGHT
var boss_multiplier = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	ThemePlayer.play_e3_bullet()
	if player_data.boss_health >= 450:
		boss_multiplier = 0
	if player_data.boss_health >= 400:
		boss_multiplier = 5
	elif player_data.boss_health >= 350:
		boss_multiplier = 10
	elif player_data.boss_health >= 300:
		boss_multiplier = 15
	elif player_data.boss_health >= 250:
		boss_multiplier = 20
	elif player_data.boss_health >= 200:
		boss_multiplier = 25
	elif player_data.boss_health >= 150:
		boss_multiplier = 30
	elif player_data.boss_health >= 100:
		boss_multiplier = 35
	else:
		boss_multiplier = 50
	speed += boss_multiplier
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
	translate(direction * speed * delta)

func _on_body_entered(body):
	if player_data.hurt_ready:
		queue_free()

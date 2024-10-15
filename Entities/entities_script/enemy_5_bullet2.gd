extends Area2D

@export var speed = 140
var direction = Vector2.RIGHT
var boss_multiplier = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	if player_data.boss_health >= 450:
		boss_multiplier = 20
	if player_data.boss_health >= 400:
		boss_multiplier = 40
	elif player_data.boss_health >= 350:
		boss_multiplier = 60
	elif player_data.boss_health >= 300:
		boss_multiplier = 80
	elif player_data.boss_health >= 250:
		boss_multiplier = 100
	elif player_data.boss_health >= 200:
		boss_multiplier = 120
	elif player_data.boss_health >= 150:
		boss_multiplier = 140
	elif player_data.boss_health >= 100:
		boss_multiplier = 160
	else:
		boss_multiplier = 200
	speed += boss_multiplier
		
	$anim.play("attack")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(direction * speed * delta)

func _on_body_entered(body):
	if body.name == "Player" and player_data.hurt_ready:
		queue_free()

func _on_queue_free_timer_timeout():
	queue_free()

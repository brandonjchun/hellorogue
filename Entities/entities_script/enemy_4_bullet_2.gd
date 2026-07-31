extends Area2D

@export var speed = 157
var direction = Vector2.RIGHT

var boss_multiplier = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	ThemePlayer.play_e4_bullet()
	if PlayerData.boss_health >= 450:
		boss_multiplier = 0
	if PlayerData.boss_health >= 400:
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
	if PlayerData.hurt_ready:
		queue_free()

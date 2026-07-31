extends Area2D

@export var health = 1
	
func _ready():
	if PlayerData.levels >= 6:
		health = 2
	if PlayerData.levels >= 12:
		health = 3
	if PlayerData.levels >= 19:
		health = 4

func _on_body_entered(body):
	if body.name == "Player":
		ThemePlayer.play_heal()
		PlayerData.health += health
		queue_free()

func _on_timer_timeout():
	queue_free()

extends Area2D

@export var ammo = 10

func _ready():
	if PlayerData.levels >= 12:
		ammo = 20
		
func _on_body_entered(body):
	# The pickup sound used to fire before this check, so any enemy that walked
	# over a dropped ammo box played the collect sound without collecting it.
	if body.name == "Player":
		ThemePlayer.play_ammo()
		PlayerData.ammo += ammo
		queue_free()

func _on_timer_timeout():
	queue_free()

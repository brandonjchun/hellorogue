extends Area2D

@export var ammo = 10

# Enemy drops are litter and clear themselves up after 5 seconds. A crate placed
# in a treasure room at level generation has to still be there when the player
# finally walks in, which may be a minute later, so those set this false.
@export var despawns := true

func _ready():
	if PlayerData.levels >= 12:
		ammo = 20
	if PlayerData.bandolier_active:
		ammo *= 2
	if not despawns:
		$Timer.stop()


func _on_body_entered(body):
	# The pickup sound used to fire before this check, so any enemy that walked
	# over a dropped ammo box played the collect sound without collecting it.
	if body.name == "Player":
		ThemePlayer.play_ammo()
		PlayerData.ammo += ammo
		queue_free()

func _on_timer_timeout():
	queue_free()

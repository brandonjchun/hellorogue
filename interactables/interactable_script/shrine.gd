extends Area2D

class_name Shrine

# Trades health for speed, for the rest of this floor only.
#
# The boon rides the same one-floor flag pattern as Culling Order and Bandolier
# (PlayerData.haste_next / haste_active, consumed in main_room._ready). Those two
# are bought between floors, so they arrive via `_next`; a shrine is touched
# mid-floor and has to take effect immediately, so it sets `haste_active`
# directly. The consumption at the top of the next _ready() is what guarantees it
# cannot follow the player out of the room it was found in -- the flag is a
# static and would otherwise last for the whole process.

const HEALTH_COST := 4

# Dimmed and desaturated once spent, so a used shrine reads as used from across
# the room rather than being something the player keeps walking back to.
const SPENT_MODULATE := Color(0.35, 0.35, 0.4, 1.0)

var _spent := false

func _on_body_entered(body: Node) -> void:
	if _spent or body.name != "Player":
		return
	# Never let the shrine be the thing that kills you. Walking into scenery
	# should not end a run, and a boon you die to is not a trade.
	if PlayerData.health <= HEALTH_COST:
		return

	_spent = true
	PlayerData.health -= HEALTH_COST
	PlayerData.haste_active = true

	# The player's speed was settled in its own _ready, so it has to be told.
	if body.has_method("refresh_speed"):
		body.refresh_speed()

	$Sprite2D.modulate = SPENT_MODULATE
	$anim.stop()

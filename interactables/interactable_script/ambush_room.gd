extends Node2D

class_name AmbushRoom

# A room that shuts behind the player and opens again when what was waiting
# inside is dead.
#
# Built entirely in code because its dimensions come from a walker stamp and are
# different every floor -- there is no fixed scene to author. The caller sets
# position and calls setup() before adding it to the tree.
#
# The tilemap cannot provide the seal: its cells were already carved open during
# generation, and re-carving them shut would leave the player looking at floor
# they cannot walk through. So the barrier is a physics ring laid just outside
# the room, drawn by this node so it is visible rather than an invisible wall.

# Physics layer bits, from project.godot layer_names. The barrier sits on the
# Tilemap layer because that is the one the player (mask 31) and every enemy
# (mask 8) already collide with -- nothing needs to learn about a new layer.
const TILEMAP_LAYER := 8
const PLAYER_LAYER := 1

const WALL_THICKNESS := 16.0
# The trigger is inset from the walls so the seal fires with the player properly
# inside the room, not while clipping its doorway.
const TRIGGER_INSET := 12.0
# Floor on the trigger's dimensions, so a room only just over the inset still
# gets a shape with positive area.
const TILE_MIN := 8.0

const SEALED_COLOUR := Color(0.85, 0.15, 0.2, 0.75)

var _world_size := Vector2.ZERO
var _sealed := false
# Set once the room has done its job, so it cannot re-arm and trap the player a
# second time on the way back through.
var _spent := false
var _live_enemies := 0

var _barrier: StaticBody2D
var _trigger: Area2D

# `size` is the room's footprint in pixels. Call before add_child().
func setup(size: Vector2) -> void:
	_world_size = size

func _ready() -> void:
	_build_trigger()
	_build_barrier()

# Enemies are parented to the level, not to this node, so they keep working in
# world space like every other enemy. This only needs to know when they die.
func register_enemy(enemy: Node) -> void:
	_live_enemies += 1
	enemy.tree_exited.connect(_on_enemy_freed)

func _build_trigger() -> void:
	var inner := Vector2(
		maxf(TILE_MIN, _world_size.x - TRIGGER_INSET * 2.0),
		maxf(TILE_MIN, _world_size.y - TRIGGER_INSET * 2.0))

	var shape := RectangleShape2D.new()
	shape.size = inner

	var collider := CollisionShape2D.new()
	collider.shape = shape

	_trigger = Area2D.new()
	_trigger.collision_layer = 0
	_trigger.collision_mask = PLAYER_LAYER
	_trigger.add_child(collider)
	_trigger.body_entered.connect(_on_trigger_body_entered)
	add_child(_trigger)

func _build_barrier() -> void:
	_barrier = StaticBody2D.new()
	# Down until sealed. Toggling the layer rather than each shape's `disabled`
	# keeps it to one property and avoids touching shapes mid-callback.
	_barrier.collision_layer = 0
	_barrier.collision_mask = 0

	for wall in _wall_rects():
		var shape := RectangleShape2D.new()
		shape.size = wall.size

		var collider := CollisionShape2D.new()
		collider.shape = shape
		collider.position = wall.get_center()
		_barrier.add_child(collider)

	add_child(_barrier)

# The four walls, in this node's local space, laid just outside the room so the
# player standing anywhere inside is never caught overlapping one as it goes up.
func _wall_rects() -> Array[Rect2]:
	var half := _world_size / 2.0
	var t := WALL_THICKNESS
	return [
		Rect2(Vector2(-half.x - t, -half.y - t), Vector2(_world_size.x + t * 2.0, t)),
		Rect2(Vector2(-half.x - t, half.y), Vector2(_world_size.x + t * 2.0, t)),
		Rect2(Vector2(-half.x - t, -half.y), Vector2(t, _world_size.y)),
		Rect2(Vector2(half.x, -half.y), Vector2(t, _world_size.y)),
	]

func _on_trigger_body_entered(body: Node) -> void:
	if _spent or _sealed or body.name != "Player":
		return
	# Everything inside died to a stray shot or a spike before the player ever
	# walked in. Sealing an empty room would just be a wall the player has to
	# wait out, so the trap quietly stands down instead.
	if _live_enemies <= 0:
		_spent = true
		return
	_seal()

func _seal() -> void:
	_sealed = true
	# Deferred because this runs inside a physics callback.
	_barrier.set_deferred("collision_layer", TILEMAP_LAYER)
	queue_redraw()

func _on_enemy_freed() -> void:
	_live_enemies -= 1
	if _sealed and _live_enemies <= 0:
		_open()

func _open() -> void:
	_sealed = false
	_spent = true
	_barrier.set_deferred("collision_layer", 0)
	_trigger.set_deferred("monitoring", false)
	queue_redraw()

func _draw() -> void:
	if not _sealed:
		return
	for wall in _wall_rects():
		draw_rect(wall, SEALED_COLOUR)

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

# The party, kept as nodes rather than only as a count.
#
# The count alone is what made the room a run-ender: the barrier does not exist
# until the player walks in, and the party start roaming 1.5s after the floor
# loads (freeze_timer, then Timer, both autostart). Over a 121-second floor they
# reliably wander out of the open room. The player then triggers the seal, kills
# everything still inside, and `_live_enemies` never reaches zero because the
# strays are outside -- and cannot be shot through the barrier either, since
# bullet_1 masks the Tilemap layer the barrier sits on. Holding the nodes lets
# _seal() put the strays back before the walls go up.
var _party: Array[Node] = []

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
	_party.append(enemy)
	enemy.tree_exited.connect(_on_enemy_freed.bind(enemy))

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
	_recall_strays()
	# Deferred because this runs inside a physics callback.
	_barrier.set_deferred("collision_layer", TILEMAP_LAYER)
	queue_redraw()

# Puts any of the party that wandered off back inside, so every enemy the seal
# is waiting on is one the player can actually reach and kill.
#
# Placed on the interior inset by one wall thickness: dropping a stray exactly
# on the boundary would leave it overlapping a wall the moment that wall goes up.
func _recall_strays() -> void:
	var interior := Rect2(-_world_size / 2.0, _world_size).grow(-WALL_THICKNESS)
	for enemy in _party:
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		var body := enemy as Node2D
		if interior.has_point(to_local(body.global_position)):
			continue
		body.global_position = to_global(Vector2(
			randf_range(interior.position.x, interior.end.x),
			randf_range(interior.position.y, interior.end.y)))

func _on_enemy_freed(enemy: Node = null) -> void:
	_live_enemies -= 1
	if enemy != null:
		_party.erase(enemy)
	# The whole level is being torn down: the barrier is on its way out too, and
	# opening a room nobody is standing in is not worth touching freed nodes for.
	if not is_instance_valid(_barrier):
		return
	if _sealed and _live_enemies <= 0:
		_open()

func _open() -> void:
	_sealed = false
	_spent = true
	_party.clear()
	_barrier.set_deferred("collision_layer", 0)
	if is_instance_valid(_trigger):
		_trigger.set_deferred("monitoring", false)
	queue_redraw()

func _draw() -> void:
	if not _sealed:
		return
	for wall in _wall_rects():
		draw_rect(wall, SEALED_COLOUR)

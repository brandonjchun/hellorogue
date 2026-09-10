extends CharacterBody2D

@onready var fx_scene = preload("res://Entities/Scenes/FX/fx_scene.tscn")
@onready var ammo_scene = preload("res://interactables/scenes/ammo_1.tscn")
@onready var health_scene = preload("res://interactables/scenes/health_1.tscn")
@onready var bullet_scene = preload("res://Entities/Scenes/Bullets/enemy_3_bullet.tscn")
@onready var final_bullet_scene = preload("res://Entities/Scenes/Bullets/enemy_3_bullet_2.tscn")
var boss_multiplier = 0
@export var speed = randi_range(27,32) + PlayerData.levels + boss_multiplier
var enemy_health = 4
var can_attack = false
@onready var enemy_collider = $enemy_collider
@onready var chase_box = $chase_box

enum enemy_state {
	FROZEN,
	MOVE,
	DEAD,
}

enum enemy_direction {
	RIGHT,
	LEFT,
	UP,
	DOWN,
	CHASE
}

var current_state = enemy_state.FROZEN
var new_direction
var change_direction

@onready var target = get_node("../Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	if PlayerData.final_level:
		$freeze_timer.wait_time = 0.3
	if PlayerData.boss_health >= 400:
		boss_multiplier = 0
	elif PlayerData.boss_health >= 300:
		boss_multiplier = 10
	elif PlayerData.boss_health >= 200:
		boss_multiplier = 20
	elif PlayerData.boss_health >= 100:
		boss_multiplier = 30
	elif PlayerData.boss_health >= 50:
		boss_multiplier = 40
	speed = randi_range(22,27) + PlayerData.levels + boss_multiplier
	if PlayerData.final_level:
		chase_box.scale = Vector2(4, 4)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# boss_multiplier and chase_box.scale were recomputed here every frame.
	# speed is only assigned in _ready, so the multiplier update did nothing.
	match current_state:
		enemy_state.MOVE:
			match new_direction:
				enemy_direction.RIGHT:
					move_right()
				enemy_direction.LEFT:
					move_left()
				enemy_direction.UP:
					move_up()
				enemy_direction.DOWN:
					move_down()
				enemy_direction.CHASE:
					chase_state()
		enemy_state.DEAD:
			enemy_collider.set_deferred("disabled", true)
			$anim.play("dead")
			

func move_right():
	velocity = Vector2.RIGHT * speed
	$anim.play("walk_right")
	move_and_slide()
	
func move_left():
	velocity = Vector2.LEFT * speed
	$anim.play("walk_left")
	move_and_slide()
	
func move_up():
	velocity = Vector2.UP * speed
	$anim.play("walk_right")
	move_and_slide()
	
func move_down():
	velocity = Vector2.DOWN * speed
	$anim.play("walk_left")
	move_and_slide()
	
func choose_direction():
	change_direction = randi_range(1, 4)
	random_direction()
	
func instance_fx():
	var fx = fx_scene.instantiate()
	fx.global_position = global_position
	Globals.spawn_transient(fx)
	
func instance_ammo():
	var ammo = ammo_scene.instantiate()
	ammo.global_position = global_position
	Globals.spawn_transient(ammo)
	
func instance_health():
	var health = health_scene.instantiate()
	health.global_position = global_position
	Globals.spawn_transient(health)
	
func instance_bullet():
	var bullet
	if not PlayerData.final_level:
		bullet = bullet_scene.instantiate()
	else:
		bullet = final_bullet_scene.instantiate()
	bullet.direction = global_position.direction_to(target.global_position)
	# The bearing from this enemy to the player, in -180..180.
	#
	# This used to be `global_position.angle_to(target.global_position)`, which
	# is the angle *between the two position vectors measured at the world
	# origin* -- not a bearing at all. For two points a few hundred pixels apart
	# out at world coordinates in the thousands it is a couple of degrees, which
	# is why the bullet's facing thresholds were the unexplainable 9.5 / 2 / -12
	# / -50. Both ends are fixed together; see enemy_3_bullet.gd.
	PlayerData.degrees_to_player = rad_to_deg(
		(target.global_position - global_position).angle())
	bullet.global_position = global_position
	Globals.spawn_transient(bullet)
	
func random_direction():
	match change_direction:
		1:
			new_direction = enemy_direction.RIGHT
		2:
			new_direction = enemy_direction.LEFT
		3:
			new_direction = enemy_direction.UP
		4:
			new_direction = enemy_direction.DOWN

func _on_freeze_timer_timeout():
	current_state = enemy_state.MOVE
	can_attack = true

func _on_timer_timeout():
	choose_direction()
	$Timer.start()


func _on_chase_box_area_entered(area):
	if area.is_in_group("follow"):
		if can_attack and not current_state == enemy_state.DEAD:
			# The body collider used to be disabled here and never re-enabled, so
			# this enemy walked through walls for the rest of its life after its
			# first shot. Nothing needed it: the bullet is an Area2D on layer 32
			# masking 11, and this body is layer 32 -- they cannot collide.
			instance_bullet()
			can_attack = false
			$attack_timer.start()
		new_direction = enemy_direction.CHASE

func ammo_chance():
	return randi_range(1, 3) == 3
	
func health_chance():
	return randi_range(1, 6) == 1

func chase_state():
	var chase_speed = speed*2
	velocity = position.direction_to(target.global_position) * chase_speed
	animation()
	move_and_slide()
	
# Vector2 comparison is lexicographic, so `velocity > Vector2.ZERO` missed every
# up-and-left diagonal and left the sprite on its previous animation.
func animation():
	# Annotated rather than inferred: `new_direction` is untyped, so `:=` here is a
	# hard parse error in 4.2 and the whole script fails to load.
	var chasing: bool = new_direction == enemy_direction.CHASE
	if velocity.x > 0:
		$anim.play("run_right" if chasing else "walk_right")
	elif velocity.x < 0:
		$anim.play("run_left" if chasing else "walk_left")

func _on_hitbox_area_entered(area):
	# Two bullets landing on the same frame both reach here, and the hitbox is
	# still live until _process runs -- so without this the drop roll and the
	# death sound fired once per bullet.
	if current_state == enemy_state.DEAD:
		return
	if area.is_in_group("Bullet"):
		instance_fx()
		enemy_health -= 1
		if enemy_health <= 0:
			enemy_collider.set_deferred("disabled", true)
			current_state = enemy_state.DEAD
			if ammo_chance():
				instance_ammo()
			elif health_chance():
				instance_health()
			$death_timer.start()
			ThemePlayer.play_e3_death()
			
func _on_death_timer_timeout():
	queue_free()

func _on_attack_timer_timeout():
	can_attack = true


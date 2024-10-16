extends CharacterBody2D

@onready var fx_scene = preload("res://Entities/Scenes/FX/fx_scene.tscn")
@onready var ammo_scene = preload("res://interactables/scenes/ammo_1.tscn")
@onready var health_scene = preload("res://interactables/scenes/health_1.tscn")
@onready var bullet_scene = preload("res://Entities/Scenes/Bullets/enemy_3_bullet.tscn")
@onready var final_bullet_scene = preload("res://Entities/Scenes/Bullets/enemy_3_bullet_2.tscn")
var boss_multiplier = 0
@export var speed = randi_range(27,32) + player_data.levels + boss_multiplier
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
	if player_data.final_level:
		$freeze_timer.wait_time = 0.3
	if player_data.boss_health >= 400:
		boss_multiplier = 0
	elif player_data.boss_health >= 300:
		boss_multiplier = 10
	elif player_data.boss_health >= 200:
		boss_multiplier = 20
	elif player_data.boss_health >= 100:
		boss_multiplier = 30
	elif player_data.boss_health >= 50:
		boss_multiplier = 40
	speed = randi_range(22,27) + player_data.levels + boss_multiplier
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player_data.boss_health >= 400:
		boss_multiplier = 0
	elif player_data.boss_health >= 300:
		boss_multiplier = 5
	elif player_data.boss_health >= 200:
		boss_multiplier = 10
	elif player_data.boss_health >= 100:
		boss_multiplier = 15
	else:
		boss_multiplier = 20
	if player_data.final_level:
		chase_box.scale = Vector2(4,4)
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
	get_tree().root.add_child(fx)
	
func instance_ammo():
	var ammo = ammo_scene.instantiate()
	ammo.global_position = global_position
	get_tree().root.add_child(ammo)
	
func instance_health():
	var health = health_scene.instantiate()
	health.global_position = global_position
	get_tree().root.add_child(health)
	
func instance_bullet():
	var bullet
	if not player_data.final_level:
		bullet = bullet_scene.instantiate()
	else:
		bullet = final_bullet_scene.instantiate()
	bullet.direction = global_position.direction_to(target.global_position)
	player_data.degrees_to_player = rad_to_deg(global_position.angle_to(target.global_position))
	bullet.global_position = global_position
	get_tree().root.add_child(bullet)
	
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
			enemy_collider.set_deferred("disabled", true)
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
	
func animation():
	if velocity > Vector2.ZERO:
		if new_direction == enemy_direction.CHASE:
			$anim.play("run_right")
		else:
			$anim.play("walk_right")
	if velocity < Vector2.ZERO:
		if new_direction == enemy_direction.CHASE:
			$anim.play("run_left")
		else:
			$anim.play("walk_left")

func _on_hitbox_area_entered(area):
	if area.is_in_group("Bullet"):
		instance_fx()
		enemy_health -= 1
		if enemy_health == 0:
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


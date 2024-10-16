extends CharacterBody2D

@onready var fx_scene = preload("res://Entities/Scenes/FX/fx_scene.tscn")
@onready var ammo_scene = preload("res://interactables/scenes/ammo_1.tscn")
@onready var health_scene = preload("res://interactables/scenes/health_1.tscn")
var boss_multiplier = 0
@export var speed = randi_range(22,27) + player_data.levels + boss_multiplier
@onready var chase_box = $chase_box

enum current_state {
	FROZEN,
	MOVE
}

enum enemy_direction {
	RIGHT,
	LEFT,
	UP,
	DOWN,
	CHASE
}
var new_direction
var change_direction
var enemy_state = current_state.FROZEN

@onready var target = get_node("../Player")
func _ready():
	if player_data.final_level:
		$freeze_timer.wait_time = 0.3
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
		chase_box.scale = Vector2(2.5, 2.5)
		
	if enemy_state == current_state.MOVE:
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

func move_right():
	velocity = Vector2.RIGHT * speed
	$anim.play("move_right")
	move_and_slide()
	
func move_left():
	velocity = Vector2.LEFT * speed
	$anim.play("move_left")
	move_and_slide()
	
func move_up():
	velocity = Vector2.UP * speed
	$anim.play("move_up")
	move_and_slide()
	
func move_down():
	velocity = Vector2.DOWN * speed
	$anim.play("move_down")
	move_and_slide()
	
func choose_direction():
	change_direction = randi_range(1, 4)
	random_direction()
	
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

func _on_timer_timeout():
	choose_direction()
	$Timer.start()


func _on_hitbox_area_entered(area):
	if area.is_in_group("Bullet"):
		ThemePlayer.play_e1_death()
		instance_fx()
		if ammo_chance():
			instance_ammo()
		elif health_chance():
			instance_health()
		queue_free()
		
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
	
func ammo_chance():
	return randi_range(1, 6) == 1
	
func health_chance():
	return randi_range(1, 12) == 1
	
func chase_state():
	var chase_speed = speed*2
	velocity = position.direction_to(target.global_position) * chase_speed
	animation()
	move_and_slide()
	
func animation():
	if velocity > Vector2.ZERO:
		$anim.play("move_right")
	if velocity < Vector2.ZERO:
		$anim.play("move_left")
		 
func _on_chase_box_area_entered(area):
	if area.is_in_group("follow"):      
		new_direction = enemy_direction.CHASE
		
func _on_freeze_timeout():
	enemy_state = current_state.MOVE

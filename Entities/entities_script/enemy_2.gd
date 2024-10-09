extends CharacterBody2D

@onready var fx_scene = preload("res://Entities/Scenes/FX/fx_scene.tscn")
@onready var ammo_scene = preload("res://interactables/scenes/ammo_1.tscn")
@onready var health_scene = preload("res://interactables/scenes/health_1.tscn")
@export var speed = randi_range(25,30)

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
	$anim.play("walkright")
	move_and_slide()
	
func move_left():
	velocity = Vector2.LEFT * speed
	$anim.play("walkleft")
	move_and_slide()
	
func move_up():
	velocity = Vector2.UP * speed
	$anim.play("walkright")
	move_and_slide()
	
func move_down():
	velocity = Vector2.DOWN * speed
	$anim.play("walkleft")
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
	return randi_range(1, 5) == 5
	
func health_chance():
	return randi_range(1, 10) == 1
	
func chase_state():
	var chase_speed = 60
	velocity = position.direction_to(target.global_position) * chase_speed
	animation()
	move_and_slide()
	
func animation():
	if velocity > Vector2.ZERO:
		$anim.play("walkright")
	if velocity < Vector2.ZERO:
		$anim.play("walkleft")
		 
func _on_chase_box_area_entered(area):
	if area.is_in_group("follow"):
		new_direction = enemy_direction.CHASE

func _on_timer_2_timeout():
	enemy_state = current_state.MOVE

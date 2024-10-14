extends CharacterBody2D

var current_state = player_states.FREEZE
enum player_states {
	FREEZE,
	MOVE,
	DEAD
}

@onready var bullet_scene = preload("res://Entities/Scenes/Bullets/bullet_1.tscn")
@onready var meleeleft_scene = preload("res://Entities/Scenes/Bullets/melee.tscn")
@onready var meleeright_scene = preload("res://Entities/Scenes/Bullets/melee_right.tscn")
@onready var trail_scene = preload("res://Entities/Scenes/FX/scent_trail.tscn")
@export var speed: int
var input_movement = Vector2()

@onready var gun = $gun_handler
@onready var gun_spr = $gun_handler/gun_sprite
@onready var bullet_point = $gun_handler/bullet_point
@onready var player = $"."


var pos
var rot
var facing_right
var melee_ready = true
var gun_ready = true
var step_ready = true

func _ready():
	player.speed = 90 + player_data.levels*5
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_state != player_states.FREEZE:
		if player_data.health <= 0:
			current_state = player_states.DEAD
			player_data.player_is_dead = true
			
		target_mouse()

		match current_state:
			player_states.MOVE:
				movement(delta)
			player_states.DEAD:
				dead()

func movement(delta):
	animations()
	input_movement = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
	
	if input_movement != Vector2.ZERO:
		velocity = input_movement * speed
	
	if input_movement == Vector2.ZERO:
		velocity = Vector2.ZERO
	
	if player_data.ammo > 0:
		gun.visible = true
	else:
		gun.visible = false
		
	if Input.is_action_just_pressed("shoot"):
		if player_data.ammo > 0:
			if gun_ready:
				gun_ready = false
				player_data.ammo -= 1
				if player_data.ammo == 0:
					$outofammo.play()
				$bullet_reset.start()
				instance_bullet()
		else:
			if melee_ready:
				melee_ready = false
				$melee_reset.start()
				if not facing_right:
					instance_meleeleft()
				else:
					instance_meleeright()

	move_and_slide()

func animations():
	if input_movement != Vector2.ZERO:
		$anim.play("move")
		if step_ready == true:
			var step_sound = randi_range(1,4)
			$step_timer.start()
			step_ready = false
			match step_sound:
				1:
					$foot1.play()
				2:
					$foot2.play()
				3:
					$foot3.play()
				4:
					$foot4.play()
	if input_movement == Vector2.ZERO:
		$anim.play("idle")


func dead():
	player_data.player_is_dead = true
	velocity = Vector2.ZERO
	gun.visible = false
	$anim.play("dead")
	await get_tree().create_timer(2).timeout
	if get_tree():
		player_data.health = 24
		player_data.ammo = 50
		player_data.levels = 1
		player_data.sound_selecter = 0
		player_data.hurt_ready = true
		player_data.player_is_dead = false
		player_data.toggle_loading_screen = true
		player_data.intermission_levels = false
			
	
func target_mouse():
	if player_data.player_is_dead == false:
		var mouse_movement = get_global_mouse_position()
		pos = global_position
		gun.look_at(mouse_movement)
		rot = rad_to_deg((mouse_movement - pos).angle())
		if rot >= -90 and rot <= 90:
			gun_spr.flip_v = false
			$Sprite2D.flip_h = false
			facing_right = true
		else:
			gun_spr.flip_v = true
			$Sprite2D.flip_h = true
			facing_right = false
	else:
		return
		
func instance_bullet():
	var bullet = bullet_scene.instantiate()
	bullet.direction = bullet_point.global_position - global_position
	bullet.global_position = bullet_point.global_position
	get_tree().root.add_child(bullet)
	
func instance_meleeleft():
	var melee = meleeleft_scene.instantiate()
	melee.global_position = bullet_point.global_position
	get_tree().root.add_child(melee)
	
func instance_meleeright():
	var melee = meleeright_scene.instantiate()
	melee.global_position = bullet_point.global_position
	get_tree().root.add_child(melee)

func reset_states():
	current_state = player_states.MOVE

func instance_trail():
	var trail = trail_scene.instantiate()
	trail.global_position = global_position
	get_tree().root.add_child(trail)

func _on_trail_timer_timeout():
	instance_trail()
	$trail_timer.start()

func _on_hitbox_area_entered(area):
	if area.is_in_group("enemy"):
		if player_data.hurt_ready:
			player_data.hurt_ready = false
			$hurt_timer.start()
			var hurt_sound = randi_range(1,3)
			match hurt_sound:
				1:
					$hurt1.play()
				2:
					$hurt2.play()
				3:
					$hurt3.play()
			flash()
			player_data.health -= 1
		
func flash():
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0.5)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0.5)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0.5)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0.5)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0.5)
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0)
	
func _on_melee_reset_timeout():
	melee_ready = true
	
func _on_bullet_reset_timeout():
	gun_ready = true

func _on_step_timer_timeout():
	step_ready = true
	
func _on_freeze_timer_timeout():
	current_state = player_states.MOVE

func _on_hurt_timer_timeout():
	player_data.hurt_ready = true

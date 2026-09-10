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

@onready var camera_2d = $Camera2D

@onready var gun = $gun_handler
@onready var gun_spr = $gun_handler/gun_sprite
@onready var bullet_point = $gun_handler/bullet_point
@onready var player = $"."


var pos
var rot
var facing_right
var already_slowed = false
var melee_ready = false
var gun_ready = false

var step_ready = true #for footstep osund

# dead() is dispatched from _process, which keeps running while current_state is
# DEAD -- so without this it was entered once per frame, each call opening its
# own two-second await. That is ~120 overlapping coroutines, every one of them
# due to call PlayerData.reset_run() and set toggle_loading_screen. Worse, the
# first reset put health back to 24 and player_is_dead back to false while
# current_state was still DEAD, so the next frame's call flipped the flag on
# again -- and ArenaLevel branches on exactly that flag to decide where the run
# goes next, making the outcome depend on sibling _process order.
var _dying = false

# What the shrine's boon is worth, and what a web costs.
const HASTE_MULTIPLIER := 1.45
const WEB_SLOW_MULTIPLIER := 0.25

# Speed before any modifier. The web slow used to divide `speed` by 4 and
# multiply it back by 4 on a timer, which only survives as long as nothing else
# ever writes speed -- a shrine touched while slowed would have had its boon
# multiplied away, or quadrupled, depending on the order. Modifiers now compose
# off this instead of off each other.
var base_speed := 0

func _ready():
	base_speed = 500 + PlayerData.levels * 5
	refresh_speed()
	if PlayerData.final_level:
		$hurt_timer.wait_time = 0.1
	# Boss room is a single large arena, so it gets a tighter camera. This was
	# being re-applied from _process on every frame of the level.
	if PlayerData.levels == 22:
		camera_2d.zoom = Vector2(3, 3)
	$Sprite2D.material.set_shader_parameter("flash_modifier", 0)

# Recomputes speed from base_speed and whatever is currently modifying it.
# Called by shrine.gd, which lands after this node's _ready has already run.
func refresh_speed() -> void:
	var multiplier := 1.0
	if PlayerData.haste_active:
		multiplier *= HASTE_MULTIPLIER
	if already_slowed:
		multiplier *= WEB_SLOW_MULTIPLIER
	player.speed = int(base_speed * multiplier)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_state != player_states.FREEZE:
		if PlayerData.health <= 0:
			current_state = player_states.DEAD
			PlayerData.player_is_dead = true
			
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
	
	if PlayerData.ammo > 0:
		gun.visible = true
	else:
		gun.visible = false
		
	if Input.is_action_just_pressed("shoot") or Input.is_action_pressed("shoot"):
		if PlayerData.ammo > 0:
			if gun_ready:
				gun_ready = false
				PlayerData.ammo -= 1
				if PlayerData.ammo == 0:
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


const DEATH_HOLD := 2.0

func dead():
	if _dying:
		return
	_dying = true

	PlayerData.player_is_dead = true
	velocity = Vector2.ZERO
	gun.visible = false
	$anim.play("dead")
	await get_tree().create_timer(DEATH_HOLD).timeout
	if not is_inside_tree():
		return
	# reset_run() also clears final_level and boss_health, which this hand
	# written list did not.
	#
	# player_is_dead is put back afterwards: the level reads it on the frame it
	# hands the run to the loading screen, to choose the restart scene over the
	# next one in the chain. reset_run() clears it, so setting it again here is
	# what keeps that decision correct.
	PlayerData.reset_run()
	PlayerData.player_is_dead = true
	PlayerData.toggle_loading_screen = true
			
	
func target_mouse():
	if PlayerData.player_is_dead == false:
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
	Globals.spawn_transient(bullet)
	
func instance_meleeleft():
	var melee = meleeleft_scene.instantiate()
	melee.global_position = bullet_point.global_position
	Globals.spawn_transient(melee)
	
func instance_meleeright():
	var melee = meleeright_scene.instantiate()
	melee.global_position = bullet_point.global_position
	Globals.spawn_transient(melee)

func reset_states():
	current_state = player_states.MOVE

func instance_trail():
	var trail = trail_scene.instantiate()
	trail.global_position = global_position
	Globals.spawn_transient(trail)

func _on_trail_timer_timeout():
	instance_trail()
	$trail_timer.start()

func _on_hitbox_area_entered(area):
	if area.is_in_group("enemy"):
		if PlayerData.hurt_ready:
			if area.is_in_group("poison"):
				PlayerData.health -= 2
			if area.is_in_group("web") and not already_slowed:
				already_slowed = true
				refresh_speed()
				$slow_timer.start()
			PlayerData.hurt_ready = false
			$hurt_timer.start()
			if PlayerData.health >= 2:
				var hurt_sound = randi_range(1,3)
				match hurt_sound:
					1:
						$hurt1.play()
					2:
						$hurt2.play()
					3:
						$hurt3.play()
			else:
				$death.play()
			flash()
			PlayerData.health -= 1
		
const FLASH_BLINKS := 5
const FLASH_INTERVAL := 0.1

# Blinks the hit shader on and off. This was 13 hand-unrolled await/set pairs,
# two of which set the same value twice in a row so one "blink" silently did
# nothing.
func flash():
	var sprite_material: Material = $Sprite2D.material
	for i in FLASH_BLINKS:
		sprite_material.set_shader_parameter("flash_modifier", 0.5)
		await get_tree().create_timer(FLASH_INTERVAL).timeout
		sprite_material.set_shader_parameter("flash_modifier", 0)
		await get_tree().create_timer(FLASH_INTERVAL).timeout
	
func _on_melee_reset_timeout():
	melee_ready = true
	
func _on_bullet_reset_timeout():
	gun_ready = true

func _on_step_timer_timeout():
	step_ready = true
	
func _on_freeze_timer_timeout():
	current_state = player_states.MOVE
	melee_ready = true
	gun_ready = true
	PlayerData.hurt_ready = true

func _on_hurt_timer_timeout():
	PlayerData.hurt_ready = true

func _on_slow_timer_timeout():
	already_slowed = false
	refresh_speed()

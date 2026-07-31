extends CharacterBody2D

@onready var fx_scene = preload("res://Entities/Scenes/FX/fx_scene.tscn")
@onready var ammo_scene = preload("res://interactables/scenes/ammo_1.tscn")
@onready var health_scene = preload("res://interactables/scenes/health_1.tscn")
@onready var bullet_scene = preload("res://Entities/Scenes/Bullets/enemy_5_bullet.tscn")
@onready var bullet2_scene = preload("res://Entities/Scenes/Bullets/enemy_5_bullet_2.tscn")
@export var speed = 50
@onready var attack_2_timer = $attack2_timer

var enemy_health = 500
var can_attack = false
var can_attack2 = false
var bullet2_enabled = false

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
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_phase()
	$Label.text = var_to_str(enemy_health)
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
	
	if can_attack and not current_state == enemy_state.DEAD:
		instance_bullet()
		can_attack = false
		$attack_timer.start()
		
	if can_attack2 and not current_state == enemy_state.DEAD:
		instance_bullet2()
		can_attack2 = false
		$attack2_timer.start()
	

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
	
func instance_bullet():
	var bullet = bullet_scene.instantiate()
	bullet.direction = (target.global_position - global_position).normalized()
	bullet.global_position = global_position
	get_tree().root.add_child(bullet)
	
func instance_bullet2():
	var bullet2 = bullet2_scene.instantiate()
	var variance = Vector2(randi_range(-64, 64), randi_range(-64, 64))
	bullet2.direction = (target.global_position - global_position + variance).normalized()
	bullet2.global_position = global_position
	get_tree().root.add_child(bullet2)
	
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

# Escalating boss phases, highest health first.
const PHASES := [
	{"at": 400, "speed": 55, "attack": [0.8, 1.0], "roar": true},
	{"at": 300, "speed": 60, "attack": [0.5, 0.7], "roar": true},
	{"at": 250, "attack2": [0.2, 0.3], "restart_attack2": true},
	{"at": 200, "speed": 65, "attack": [0.3, 0.5], "roar": true},
	{"at": 150, "attack2": [0.1, 0.2]},
	{"at": 100, "speed": 70, "attack": [0.1, 0.4], "roar": true},
	{"at": 50, "speed": 75, "attack": [0.05, 0.15], "attack2": [0.03, 0.03], "roar": true},
]

var _phase := -1

# This was a `match PlayerData.boss_health:` on exact values, run from _process.
# Two problems: while health sat on a phase number the whole branch re-ran every
# frame, so $boss_roar.play() restarted 60 times a second; and any hit that took
# health straight past a value (two bullets landing on one frame) skipped that
# phase entirely. Thresholds plus a "only on change" guard fix both.
func update_phase() -> void:
	var target := _phase
	for i in PHASES.size():
		if PlayerData.boss_health <= PHASES[i]["at"]:
			target = i
	if target == _phase:
		return
	_phase = target
	apply_phase(PHASES[_phase])

func apply_phase(phase: Dictionary) -> void:
	if phase.has("speed"):
		speed = phase["speed"]
	if phase.has("attack"):
		$attack_timer.wait_time = randf_range(phase["attack"][0], phase["attack"][1])
	if phase.has("attack2"):
		$attack2_timer.wait_time = randf_range(phase["attack2"][0], phase["attack2"][1])
	if phase.get("restart_attack2", false):
		$attack2_timer.stop()
		$attack2_timer.start()
	if phase.get("roar", false):
		$boss_roar.play()

func _on_freeze_timer_timeout():
	current_state = enemy_state.MOVE
	can_attack = true
	can_attack2 = true
	
func _on_timer_timeout():
	choose_direction()
	$Timer.start()


func _on_chase_box_area_entered(area):
	if area.is_in_group("follow"):
		new_direction = enemy_direction.CHASE

func chase_state():
	var chase_speed = speed*2
	velocity = position.direction_to(target.global_position) * chase_speed
	animation()
	move_and_slide()
	
# Vector2 comparison is lexicographic, so `velocity > Vector2.ZERO` missed every
# up-and-left diagonal and left the sprite on its previous animation.
func animation():
	if velocity.x > 0:
		$anim.play("walk_right")
	elif velocity.x < 0:
		$anim.play("walk_left")

func _on_hitbox_area_entered(area):
	if area.is_in_group("Bullet"):
		instance_fx()
		enemy_health -= 1
		PlayerData.boss_health -= 1
		if enemy_health <= 0:
			current_state = enemy_state.DEAD
			queue_free()

func _on_attack_timer_timeout():
	can_attack = true

func _on_attack_2_timer_timeout():
	can_attack2 = true

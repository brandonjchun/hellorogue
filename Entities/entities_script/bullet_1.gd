extends Area2D

@onready var fx_scene = preload("res://Entities/Scenes/FX/fx_scene.tscn")
@export var speed = 50
var direction = Vector2.RIGHT
var sfx_finished = false
var was_body_entered = false
var left_screen = false
@onready var bullet_1 = $"."

# Called when the node enters the scene tree for the first time.
func _ready():
	$bullet_sound.finished.connect(on_sfx_finished)
	$bullet_sound.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(direction * speed * delta)
	if sfx_finished and was_body_entered:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("tilemap"):
		instance_fx()
	if was_body_entered == false:
		if not left_screen:
			Globals.camera.screen_shake(1.5,0.5,0.01)
		$Timer.start()
		hide()
		if sfx_finished:
			queue_free()
		else:
			was_body_entered = true

func instance_fx():
	var fx = fx_scene.instantiate()
	fx.global_position = global_position
	get_tree().root.add_child(fx)
	
func on_sfx_finished():
	sfx_finished = true

func _on_visible_screen_exited():
	left_screen = true

func _on_timer_timeout():
	$CollisionShape2D.set_deferred("disabled", true)

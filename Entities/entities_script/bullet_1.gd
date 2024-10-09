extends Area2D

@onready var fx_scene = preload("res://Entities/Scenes/FX/fx_scene.tscn")
@export var speed = 75
var direction = Vector2.RIGHT

# Called when the node enters the scene tree for the first time.
func _ready():
	$bullet_sound.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(direction * speed * delta)

func _on_body_entered(body):
	Globals.camera.screen_shake(1,1,0.01)
	instance_fx() 
	$Timer.start()

func _on_visible_screen_exited():
	queue_free()
	
func instance_fx():
	var fx = fx_scene.instantiate()
	fx.global_position = global_position
	get_tree().root.add_child(fx)

func _on_timer_timeout():
	queue_free()

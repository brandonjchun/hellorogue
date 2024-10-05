extends Camera2D

var start_shaking = false
var shake_intensity: float = 0.0
var shake_dampening: float = 0.0

@onready var camera_shake = $camera_shake

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.camera = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if start_shaking == true:
		offset.x = randi_range(-1, 1) * shake_intensity
		offset.y = randi_range(-1, 1) * shake_intensity
		shake_intensity = lerp(shake_intensity, 0.0, shake_dampening)
	else:
		offset = Vector2(0,0)
	
func screen_shake(intensity, duration, dampening):
	shake_intensity = intensity
	camera_shake.wait_time = duration
	shake_dampening = dampening
	start_shaking = true
	
func _on_camera_shake_timeout():
	start_shaking = false

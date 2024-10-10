extends Area2D
@onready var main_mouse_icon = $"."

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	global_position = get_global_mouse_position()
	if get_tree().paused or not player_data.game_mouse:
		main_mouse_icon.visible = true
	else:
		main_mouse_icon.visible = true

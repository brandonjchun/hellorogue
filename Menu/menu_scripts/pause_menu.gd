extends Control

@onready var sounds_menu = $Sounds_Menu
@onready var color_rect = $ColorRect
@onready var panel = $Panel

func resume():
	get_tree().paused = false
	$anim.play_backwards("blur")

func pause():
	get_tree().paused = true
	$anim.play("blur")
	
func testEsc():
	if Input.is_action_just_pressed("esc") and !get_tree().paused:
		pause()
		player_data.game_mouse = not player_data.game_mouse
	elif Input.is_action_just_pressed("esc") and get_tree().paused:
		resume()
		player_data.game_mouse = not player_data.game_mouse
		
# Called when the node enters the scene tree for the first time.
func _ready():
	$anim.play("RESET")
	sounds_menu.exit_sounds_menu.connect(on_exit_sounds_menu)
	sounds_menu.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	testEsc()

func _on_resume_pressed():
	resume()

func _on_quit_pressed():
	get_tree().quit()

func _on_reset_pressed():
	player_data.toggle_loading_screen = true

func _on_sounds_pressed():
	sounds_menu.visible = true
	color_rect.visible = false
	panel.visible = false
	
func on_exit_sounds_menu() -> void:
	color_rect.visible = true
	panel.visible = true
	sounds_menu.visible = false

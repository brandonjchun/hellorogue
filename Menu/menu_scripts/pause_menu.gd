extends Control

func resume():
	get_tree().paused = false
	$anim.play_backwards("blur")
	
func pause():
	get_tree().paused = true
	$anim.play("blur")
	
func testEsc():
	if (Input.is_action_just_pressed("esc") or Input.is_action_just_pressed("ui_accept")) and !get_tree().paused:
		pause()
	elif (Input.is_action_just_pressed("esc") or Input.is_action_just_pressed("ui_accept")) and get_tree().paused:
		resume()
		
# Called when the node enters the scene tree for the first time.
func _ready():
	$anim.play("RESET")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	testEsc()

func _on_resume_pressed():
	resume()

func _on_quit_pressed():
	get_tree().quit()

func _on_reset_pressed():
	player_data.toggle_loading_screen = true

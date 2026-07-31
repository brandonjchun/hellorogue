extends Control

@onready var sounds_menu = $Sounds_Menu
@onready var color_rect = $ColorRect
@onready var panel = $Panel
@onready var pause_menu = $"."

signal exit_pause_menu
signal enter_pause_menu

func resume():
	PlayerData.pause_active = false
	PlayerData.game_mouse = true
	exit_pause_menu.emit()
	get_tree().paused = false
	
	ThemePlayer.theme_ninetales_stop()
	$anim.play_backwards("blur")

func pause():
	PlayerData.pause_active = true
	PlayerData.game_mouse = false
	
	enter_pause_menu.emit()
	get_tree().paused = true
	
	ThemePlayer.theme_ninetales()
	$anim.play("blur")
	
func testEsc():
	if Input.is_action_just_pressed("esc") and not get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("esc") and get_tree().paused:
		resume()
		
# Called when the node enters the scene tree for the first time.
func _ready():
	$anim.play("RESET")
	sounds_menu.exit_sounds_menu.connect(on_exit_sounds_menu)
	sounds_menu.visible = false
	pause_menu.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	testEsc()

func _on_resume_pressed():
	if PlayerData.pause_active:
		resume()

func _on_quit_pressed():
	
	if PlayerData.pause_active:
		get_tree().quit()

func _on_reset_pressed():
	PlayerData.reset_button_hit = true
	if PlayerData.pause_active:
		get_tree().paused = false
		PlayerData.toggle_loading_screen = true

func _on_sounds_pressed():
	if PlayerData.pause_active:
		sounds_menu.visible = true
		color_rect.visible = false
		panel.visible = false
	
func on_exit_sounds_menu() -> void:
	color_rect.visible = true
	panel.visible = true
	sounds_menu.visible = false

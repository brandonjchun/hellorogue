class_name MainMenu
extends Control

@onready var start_button = $MarginContainer/HBoxContainer/VBoxContainer/StartButton as Button
@onready var sounds_button = $MarginContainer/HBoxContainer/VBoxContainer/SoundButton as Button
@onready var controls_button = $MarginContainer/HBoxContainer/VBoxContainer/ControlsButton as Button
@onready var exit_button = $MarginContainer/HBoxContainer/VBoxContainer/QuitButton as Button
@onready var controls_menu = $Control as ControlsMenu
@onready var sounds_menu = $Sounds_Menu as SoundsMenu

@onready var texture_rect = $TextureRect
@onready var margin_container = $MarginContainer as MarginContainer

@onready var start_game = preload("res://Menu/loading_screen.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	ThemePlayer.theme_questionairre()
	controls_menu.visible = false
	sounds_menu.visible = false
	handle_connecting_signals()
	
func on_start_pressed() -> void:
	get_tree().change_scene_to_packed(start_game)
	ThemePlayer.theme_questionairre_stop()
	
func on_sounds_pressed() -> void:
	margin_container.visible = false
	texture_rect.visible = false
	sounds_menu.set_process(true)
	sounds_menu.visible = true
	ThemePlayer.theme_questionairre_stop()
	ThemePlayer.theme_fileselect()
	
func on_controls_pressed() -> void:
	margin_container.visible = false
	controls_menu.set_process(true)
	controls_menu.visible = true
	
func on_exit_pressed() -> void:
	get_tree().quit()
	
func on_exit_controls_menu() -> void:
	margin_container.visible = true
	controls_menu.visible = false
	
func on_exit_sounds_menu() -> void:
	ThemePlayer.theme_fileselect_stop()
	ThemePlayer.theme_questionairre()
	margin_container.visible = true
	texture_rect.visible = true
	sounds_menu.visible = false

func handle_connecting_signals() -> void:
	start_button.button_down.connect(on_start_pressed)
	controls_button.button_down.connect(on_controls_pressed)
	sounds_button.button_down.connect(on_sounds_pressed)
	exit_button.button_down.connect(on_exit_pressed)
	controls_menu.exit_controls_menu.connect(on_exit_controls_menu)
	sounds_menu.exit_sounds_menu.connect(on_exit_sounds_menu)
	

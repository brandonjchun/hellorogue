class_name MainMenu
extends Control

@onready var start_button = $MarginContainer/HBoxContainer/VBoxContainer/StartButton as Button
@onready var sound_button = $MarginContainer/HBoxContainer/VBoxContainer/SoundButton as Button
@onready var controls_button = $MarginContainer/HBoxContainer/VBoxContainer/ControlsButton as Button
@onready var exit_button = $MarginContainer/HBoxContainer/VBoxContainer/QuitButton as Button
@onready var controls_menu = $Control as ControlsMenu

@onready var texture_rect = $TextureRect
@onready var margin_container = $MarginContainer as MarginContainer

@onready var start_game = preload("res://Levels/main_level.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	controls_menu.visible = false
	handle_connecting_signals()
	
func on_start_pressed() -> void:
	get_tree().change_scene_to_packed(start_game)
	
func on_sound_pressed() -> void:
	margin_container.visible = false
	
func on_controls_pressed() -> void:
	margin_container.visible = false
	controls_menu.set_process(true)
	controls_menu.visible = true
	
func on_exit_pressed() -> void:
	get_tree().quit()
	
func on_exit_controls_menu() -> void:
	margin_container.visible = true
	controls_menu.visible = false

	
func handle_connecting_signals() -> void:
	start_button.button_down.connect(on_start_pressed)
	controls_button.button_down.connect(on_controls_pressed)
	exit_button.button_down.connect(on_exit_pressed)
	controls_menu.exit_controls_menu.connect(on_exit_controls_menu)
	

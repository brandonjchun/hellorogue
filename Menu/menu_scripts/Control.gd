class_name ControlsMenu
extends Control

@onready var exit_button = $VBoxContainer/Button as Button

signal exit_controls_menu

func _ready() -> void:
	exit_button.button_down.connect(on_exit_pressed)
	set_process(false)
	
func on_exit_pressed() -> void:
	exit_controls_menu.emit()
	set_process(false)

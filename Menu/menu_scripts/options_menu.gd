extends Control

@onready var exit_button = $MarginContainer/VBoxContainer/Exit_Button as Button

signal exit_controls_menu

# Called when the node enters the scene tree for the first time.
func _ready():
	exit_button.button_down.connect(on_exit_pressed)
	set_process(false)

func on_exit_pressed() -> void:
	exit_controls_menu.emit()
	set_process(false)

class_name SoundsMenu
extends Control

signal exit_sounds_menu

@onready var exit_button = $MarginContainer/Button as Button

# Called when the node enters the scene tree for the first time.
func _ready():
	exit_button.button_down.connect(on_exit_pressed)
	set_process(false)

func on_exit_pressed() -> void:
	exit_sounds_menu.emit()
	set_process(false)
	self.visible = false
	

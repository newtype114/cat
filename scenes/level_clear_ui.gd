
extends Control

signal next_level_pressed

@onready var next_button := $NextLevelButton

func _ready():
	next_button.pressed.connect(_on_next_level_button_pressed)

func _on_next_level_button_pressed():
	print("LevelClearUI: 下一关按钮被点击")
	emit_signal("next_level_pressed")

extends Sprite2D


@onready var touch_screen_button: TouchScreenButton = $TouchScreenButton
const PAUSE_MENU = preload("res://Scenes/PauseMenu.tscn")


func _on_touch_screen_button_pressed() -> void:
	%AudioStreamPlayer2D.play()
	modulate = Color(0, 1, 0, 0.5)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	modulate = Color(1, 1, 1, 1)  # Reset to normal
	var new_pause = PAUSE_MENU.instantiate()
	get_parent().add_child(new_pause)

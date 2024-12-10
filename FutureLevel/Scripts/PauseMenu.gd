extends Control


@onready var continuebutton: Label = $Panel/Continue
@onready var restart: Label = $Panel/Restart
@onready var home: Label = $Panel/Home

func _ready() -> void:
	get_tree().paused = true

func _on_continue_game_pressed() -> void:
	get_tree().paused = false
	%AudioStreamPlayer2D.play()
	continuebutton.modulate = Color(0, 1, 0, 0.5)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	continuebutton.modulate = Color(1, 1, 1, 1)  # Reset to normal
	queue_free()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	%AudioStreamPlayer2D.play()
	restart.modulate = Color(0, 1, 0, 0.5)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	restart.modulate = Color(1, 1, 1, 1)  # Reset to normal
	get_tree().reload_current_scene()




func _on_home_pressed() -> void:
	get_tree().paused = false
	%AudioStreamPlayer2D.play()
	home.modulate = Color(0, 1, 0, 0.5)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	home.modulate = Color(1, 1, 1, 1)  # Reset to normal
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

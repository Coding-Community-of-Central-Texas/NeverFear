extends Node2D

@onready var restart: TouchScreenButton = $CanvasLayer/ColorRect/Restart
@onready var back_to_main_menu: TouchScreenButton = $"CanvasLayer/ColorRect/Back to Main Menu"

func _ready() -> void:
	get_tree().paused = true
	
func _on_restart_pressed() -> void:
	get_tree().paused = false
	%AudioStreamPlayer2D.play()
	restart.modulate = Color(0, 1, 0, 0.5)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	restart.modulate = Color(1, 1, 1, 1)  # Reset to normal
	Global.reset_game_state()
	get_tree().reload_current_scene()




func _on_back_to_main_menu_pressed() -> void:
	get_tree().pasued = false 
	%AudioStreamPlayer2D.play()
	back_to_main_menu.modulate = Color(0, 1, 0, 0.5)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	back_to_main_menu.modulate = Color(1, 1, 1, 1)  # Reset to normal
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

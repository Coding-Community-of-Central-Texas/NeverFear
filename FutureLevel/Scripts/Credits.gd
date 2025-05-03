extends Node2D


@onready var home_button: TouchScreenButton = $CanvasLayer/HomeButton


func _on_home_button_pressed() -> void:
	%AudioStreamPlayer2D.play()
	await get_tree().create_timer(0.5).timeout  # Wait for 0.1 seconds
	get_tree().change_scene_to_file("res://Scenes/HubWorld.tscn")

extends Node2D



func _on_restart_pressed() -> void:
	Global.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

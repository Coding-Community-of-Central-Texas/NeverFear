extends Node2D



func _on_restart_pressed() -> void:
	Global.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/LegacyProtocol.tscn")



func _on_back_to_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

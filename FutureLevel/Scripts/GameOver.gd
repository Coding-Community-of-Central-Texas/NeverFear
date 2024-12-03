extends Node2D



func _on_restart_pressed() -> void:
	Global.reset_game_state()
	if get_tree().current_scene.name == ("LegacyProtocol"):
		get_tree().change_scene_to_file("res://Scenes/LegacyProtocol.tscn")
	else: 
		get_tree().change_scene_to_file("res://Scenes/HypercoreGauntlet.tscn")



func _on_back_to_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

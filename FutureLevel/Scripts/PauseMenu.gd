extends CanvasLayer

@onready var continue_game: TouchScreenButton = $TextureRect/Continue/continue_game
@onready var restart: TouchScreenButton = $TextureRect/Restart/Restart
@onready var home: TouchScreenButton = $TextureRect/Home/Home



func _on_continue_game_pressed() -> void:
	GameManager.toggle_pause()


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/HypercoreGauntlet.tscn")




func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

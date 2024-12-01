extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)



func _on_touch_screen_button_pressed() -> void:
	Global.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

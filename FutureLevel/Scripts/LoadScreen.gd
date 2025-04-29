extends Node

var gpgs

func _ready():
	gpgs = Engine.get_singleton("GodotPlayGamesServices")
	if gpgs:
		gpgs.sign_in()
	else:
		print("Google Play Services plugin not found!")

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://Scenes/HubWorld.tscn")

extends Node

@onready var gps = GodotPlayGameServices

func _ready():
	if gps:
		print("Google Play Services autoload present.")
		SignIn.sign_in()
	else:
		print("Google Play Services autoload NOT found.")


func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://Scenes/HubWorld.tscn")

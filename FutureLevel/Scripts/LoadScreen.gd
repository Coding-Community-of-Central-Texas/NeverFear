extends Node

var plugin 

func _enter_tree() -> void:
	plugin = Engine.get_singleton("SignIn")
	plugin.sign_in()


func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://Scenes/HubWorld.tscn")

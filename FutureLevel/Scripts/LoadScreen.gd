extends AspectRatioContainer

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://Scenes/HubWorld.tscn")

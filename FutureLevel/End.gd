extends Area2D



func _on_tree_exiting():
	
	var level_time = Global.legacy.Timer.time_elapsed

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://Scenes/WinScreen.tscn")

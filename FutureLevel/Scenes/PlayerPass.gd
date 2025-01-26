extends Area2D



func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://Scenes/PerformanceIndex.tscn")

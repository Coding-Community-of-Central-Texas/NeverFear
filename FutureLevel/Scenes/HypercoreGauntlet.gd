extends Node2D



func _on_scene_transition() -> void:
	GameManager.reset_scene_kills()

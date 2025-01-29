extends Node2D

func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()

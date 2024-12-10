extends Area2D
signal picked_up




func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):
		emit_signal("picked_up")

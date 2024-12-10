extends Area2D



func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.Camera2D.set_zoom(2,2)
	if body.has_method("_on_body_entered(body)"):
		_on_body_entered(body)
		

extends Area2D


func _on_body_entered(body):
	if body.is_in_group("player"):
		Global.checkpoint_position = global_position  # Update the checkpoint

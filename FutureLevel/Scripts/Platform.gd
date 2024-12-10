extends AnimatableBody2D

const GRAVITY = 2000
const FRICTION = 2000

func _on_area_2d_body_entered(body) -> void:
	if body.is_in_group("player"):
		%AnimationPlayer.play("move")

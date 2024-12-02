extends AnimatableBody2D

const GRAVITY = 200
const FRICTION = 1000

func _on_area_2d_body_entered(body) -> void:
	if body.is_in_group("player"):
		%AnimationPlayer.play("move")

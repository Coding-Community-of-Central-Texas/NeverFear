extends AnimatableBody2D

@onready var area_2d: Area2D = $Area2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		%AnimationPlayer.play("end")

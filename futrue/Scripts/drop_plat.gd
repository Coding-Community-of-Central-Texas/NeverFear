extends AnimatableBody2D

@onready var timer: Timer = $Timer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%AnimationPlayer.play("RESET")




func _on_area_2d_body_entered(body) -> void:
	if body.is_in_group("player"):
		timer.start()



func _on_timer_timeout() -> void:
	collision_shape_2d.disabled = true
	%AnimationPlayer.play("end")

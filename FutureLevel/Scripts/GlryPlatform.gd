extends AnimatableBody2D


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _on_area_2d_body_entered(body):

	if body.is_in_group("player"): 
		play_move()

func play_move():
	animation_player.play("move")

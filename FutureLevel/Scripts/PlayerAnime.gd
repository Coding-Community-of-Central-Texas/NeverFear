extends Skeleton2D


@onready var animation_player: AnimationPlayer = $AnimationPlayer

func left_face():
	animation_player.play("runleft")

func right_face():
	animation_player.play("runright")

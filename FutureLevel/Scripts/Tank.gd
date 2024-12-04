extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func play_move():
	%AnimationPlayer.play("move")

func play_hurt():
	%AnimationPlayer.play("hurt")

func _flip():
	animated_sprite_2d.flip_h = true

func play_die():
	%AnimationPlayer.play("die")

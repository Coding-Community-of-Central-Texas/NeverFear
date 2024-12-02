extends Node2D

func play_move():
	%AnimationPlayer.play("move")

func play_hurt():
	%AnimationPlayer.play("hurt")
	%AnimationPlayer.queue("move")

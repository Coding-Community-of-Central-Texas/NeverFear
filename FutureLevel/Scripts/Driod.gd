extends Node2D

func play_walk():
	%AnimationPlayer.play("move")

func play_die():
	%AnimationPlayer.play("death")

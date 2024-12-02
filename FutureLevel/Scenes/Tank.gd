extends Node2D

func play_walk():
	%AnimationPlayer.play("mpve")

func play_hurt():
	%AnimationPlayer.play("hurt")
	%AnimationPlayer.queue("move")

extends Node2D


func boss_bang():
	position.x = -7; position.y = -20;
	scale.x = 2.84; scale.y = 3.96;
	%AnimatedSprite2D.play("bossBoom")
	%AudioStreamPlayer2D.play()

func little_impact():
	scale.x = 0.76; scale.y = 0.72;
	%AnimatedSprite2D.play("pact")

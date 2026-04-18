extends Node2D


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func play_move():
	animated_sprite_2d.play("move")

func play_attack():
	animated_sprite_2d.play("attack")

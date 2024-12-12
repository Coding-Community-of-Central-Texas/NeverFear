extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2



func play_move():
	%AnimationPlayer.play("move")

func play_hurt():
	%AnimationPlayer.play("hurt")

func _flip():
	animated_sprite_2d.flip_h = true

func _impact():
	animated_sprite_2d_2.play("impact")
	%BigBoom.little_impact()
	%PathFollow2D.progress_ratio = randf()
	animated_sprite_2d_2.position = %PathFollow2D.position
	%BigBoom.position = %PathFollow2D.position

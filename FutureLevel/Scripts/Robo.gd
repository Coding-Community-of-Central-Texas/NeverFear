extends Node2D

@onready var animated_sprite_2d_2: AnimatedSprite2D = $Impacts


func play_walk():
	%AnimationPlayer.play("walk")

func play_hurt():
	%AnimationPlayer.play("hurt")
	_impact()
	
func play_attack():
	%AnimationPlayer.play("attack")

func play_die():
	_impact()
	_impact()
	%BigBoom.boss_bang()

func _impact():
	animated_sprite_2d_2.play("impact1")
	animated_sprite_2d_2.play("impact2")
	%BigBoom.little_impact()
	%PathFollow2D.progress_ratio = randf()
	animated_sprite_2d_2.position = %PathFollow2D.position
	%BigBoom.position = %PathFollow2D.position
	

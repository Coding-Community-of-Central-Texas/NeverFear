extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func play_walk():
	%AnimationPlayer.play("walk")

func play_hurt():
	%AnimationPlayer.play("hurt")
	%AnimationPlayer.queue("walk")

func _on_frame_changed():
	$AnimatedSprite2D.material.set("shader_parameter/albedo_color", Color(randf(), randf(), 0.0))

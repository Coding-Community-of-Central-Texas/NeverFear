extends Node2D

signal enemy_killed(enemy_type)

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func play_walk():
	%AnimationPlayer.play("walk")

func play_hurt():
	%AnimationPlayer.play("hurt")
	%AnimationPlayer.queue("walk")

func _on_frame_changed():
	$AnimatedSprite2D.material.set("shader_parameter/albedo_color", Color(randf(), randf(), 0.0))

# Assuming this function is called when the enemy is killed
func die():
	emit_signal("enemy_killed", "Byte")
	queue_free()

extends Node2D

@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2

func play_walk():
	%AnimationPlayer.play("walk")

func play_hurt():
	self.modulate = Color(1, 0, 0)  # Set to red
	await get_tree().create_timer(0.1).timeout  # Wait for 0.1 seconds
	self.modulate = Color(1, 1, 1)  # Reset to normal
	_impact()

func _impact():
	animated_sprite_2d_2.play("impact")
	%PathFollow2D.progress_ratio = randf()
	animated_sprite_2d_2.position = %PathFollow2D.position

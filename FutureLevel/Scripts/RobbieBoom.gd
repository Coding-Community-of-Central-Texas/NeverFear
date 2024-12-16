extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D



func _ready():
	if animated_sprite:
		animated_sprite.play("RobbieBoom")
	audio_stream_player_2d.play()
	cpu_particles_2d.emitting = true


func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()

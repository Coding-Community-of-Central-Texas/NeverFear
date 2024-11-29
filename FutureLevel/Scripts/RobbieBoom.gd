extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D



func _ready():
	if animated_sprite:
		animated_sprite.play("RobbieBoom")
	audio_stream_player_2d.play()


func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()

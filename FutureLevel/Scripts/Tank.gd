extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func play_move():
	%AnimationPlayer.play("move")

func play_hurt():
	%AnimationPlayer.play("hurt")

func _flip():
	animated_sprite_2d.flip_h = true

func play_die():
	%AnimationPlayer.play("hurt")
	animated_sprite_2d_2.play("boom")
	audio_stream_player.play()

extends Area2D

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var has_sound_played: bool = false
var has_animation_played: bool = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		if not has_animation_played:
			animation_player.play("check")
			has_animation_played = true  # Ensure animation plays only once
		if not has_sound_played:
			audio_stream_player.play()
			has_sound_played = true
		Global.checkpoint_position = global_position  # Update the checkpoint

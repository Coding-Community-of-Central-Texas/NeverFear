extends Area2D


@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready():
	audio_stream_player.play()

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		Global.legacy.end()

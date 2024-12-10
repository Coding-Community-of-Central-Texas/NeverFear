extends Area2D


@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready():
	audio_stream_player.play()

func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):
		const WIN = preload("res://Scenes/WinScreen.tscn")
		var new_win = WIN.instantiate()
		add_child(new_win)
		Global.legacy.complete_level()

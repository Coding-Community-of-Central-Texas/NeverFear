extends Area2D

@onready var legacy_protocol: Node2D = $".."
@onready var timer: Timer = $"../Timer"
@onready var winner: CanvasLayer = $Winner
@onready var audio_stream_player: AudioStreamPlayer = $"../AudioStreamPlayer"


func _ready():
	audio_stream_player.play()

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		Global.legacy.timer.stop()
		winner.visible = true 

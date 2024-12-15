extends TextureRect

@onready var label: Label = $StatsLink/Label
@onready var run_time: Label = $RunTime
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D


func _ready():
	if DisplayServer.is_touchscreen_available() and OS.has_feature("Andriod"):
		get_viewport().screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	else:
		pass

func _process(_delta):
	run_time.text = "YOUR COMPLETION TIME: "
	




func _on_stats_link_pressed() -> void:
	audio_stream_player_2d.play()
	label.modulate = Color(0, 1, 0, 0.5)  # Set to red
	await get_tree().create_timer(0.5).timeout  # Wait for 0.1 seconds
	label.modulate = Color(1, 1, 1)  # Reset to normal
	Engine.time_scale = 1.0
	Global.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/PerformanceIndex.tscn")

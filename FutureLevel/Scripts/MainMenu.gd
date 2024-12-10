extends CanvasLayer

@onready var legacy_protocol: TouchScreenButton = %LegacyProtocol
@onready var hypercore_gauntlet: TouchScreenButton = %HypercoreGauntlet
@onready var performance: TouchScreenButton = %Performance
@onready var credits: TouchScreenButton = %Credits
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var survival: Label = $MenuBox/Survival
@onready var performance_settings: Label = $MenuBox/PerformanceSettings
@onready var credits_label: Label = $MenuBox/Credits
@onready var story: Label = $MenuBox/Story



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if DisplayServer.is_touchscreen_available() and OS.has_feature("Andriod"):
		get_viewport().screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	else:
		return


func _on_legacy_protocol_pressed() -> void:
	audio_stream_player_2d.play()
	story.modulate = Color(0, 1, 0, 0.5)  # Set to red
	await get_tree().create_timer(0.5).timeout  # Wait for 0.1 seconds
	story.modulate = Color(1, 1, 1)  # Reset to normal
	Global.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/LegacyProtocol.tscn")


func _on_hypercore_gauntlet_pressed() -> void:
	audio_stream_player_2d.play()
	survival.modulate = Color(0, 1, 0, 0.5)  # Set to red
	await get_tree().create_timer(0.5).timeout  # Wait for 0.1 seconds
	survival.modulate = Color(1, 1, 1)  # Reset to normal
	get_tree().change_scene_to_file("res://Scenes/HypercoreGauntlet.tscn")
	Global.reset_game_state()


func _on_credits_pressed() -> void:
	audio_stream_player_2d.play()
	credits_label.modulate = Color(0, 1, 0, 0.5)  # Set to red
	await get_tree().create_timer(0.5).timeout  # Wait for 0.1 seconds
	credits_label.modulate = Color(1, 1, 1)  # Reset to normal
	get_tree().change_scene_to_file("res://Scenes/Credits.tscn")


func _on_performance_pressed() -> void:
	audio_stream_player_2d.play()
	performance_settings.modulate = Color(0, 1, 0, 0.5)  # Set to red
	await get_tree().create_timer(0.5).timeout  # Wait for 0.1 seconds
	performance_settings.modulate = Color(1, 1, 1)  # Reset to normal
	get_tree().change_scene_to_file("res://Scenes/PerformanceIndex.tscn")

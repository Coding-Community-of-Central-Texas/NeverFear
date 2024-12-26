extends CanvasLayer

@onready var legacy_protocol: TouchScreenButton = %LegacyProtocol
@onready var hypercore_gauntlet: TouchScreenButton = %HypercoreGauntlet
@onready var performance: TouchScreenButton = %Performance
@onready var credits: TouchScreenButton = %Credits
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var performance_settings: Label = $MenuBox/Performance/PerformanceSettings
@onready var credits_label: Label = $MenuBox/Credits
@onready var legacy_button: Sprite2D = $MenuBox/LegacyButton
@onready var gauntlet: Sprite2D = $MenuBox/Gauntlet





func _on_legacy_protocol_pressed() -> void:
	audio_stream_player_2d.play()
	legacy_button.modulate = Color(0.5, 0.5, 0, 0.7)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	legacy_button.modulate = Color(1, 1, 1, 1)  # Reset to normal
	Global.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/LegacyProtocol.tscn")


func _on_hypercore_gauntlet_pressed() -> void:
	audio_stream_player_2d.play()
	gauntlet.modulate = Color(0.5, 0.5, 0, 0.7)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	gauntlet.modulate = Color(1, 1, 1, 1)  # Reset to normal
	GameManager.reset_scene_kills()
	get_tree().change_scene_to_file("res://Scenes/HypercoreGauntlet.tscn")
	Global.reset_game_state()


func _on_credits_pressed() -> void:
	audio_stream_player_2d.play()
	credits_label.modulate = Color(0.5, 0.5, 0, 0.7)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	credits_label.modulate = Color(1, 1, 1, 1)  # Reset to normal
	get_tree().change_scene_to_file("res://Scenes/Credits.tscn")


func _on_performance_pressed() -> void:
	audio_stream_player_2d.play()
	performance_settings.modulate = Color(0.5, 0.5, 0, 0.7)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	performance_settings.modulate = Color(1, 1, 1, 1)  # Reset to normal
	get_tree().change_scene_to_file("res://Scenes/PerformanceIndex.tscn")

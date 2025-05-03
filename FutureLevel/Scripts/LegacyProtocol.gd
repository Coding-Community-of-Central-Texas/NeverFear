extends Node2D

@onready var time_panel: Panel = %TimePanel
@onready var upscale: Sprite2D = $TileMap/CityBack/Background/Upscale

func _ready():
	Global.legacy = self
	Engine.time_scale = 1.0
	GameManager.reset_legacy_protocol_stats()

func complete_level():
	# Call stop() on the timer and get the formatted time
	%TimePanel.stop()
	var formatted_time = %TimePanel.get_time_formated()  # Now it will call the stop function from the Panel script
	var time_in_ms = GameManager.time_to_ms(formatted_time)
	GameManager.update_quickest_time(formatted_time)  # Pass the formatted time to the GameManager
	GameManager.complete_legacy_protocol(time_in_ms)
	GameManager.save_data()  # Save the game data

func level_time() -> String: 
	%TimePanel.stop()
	var formatted_time = %TimePanel.get_time_formated()
	return formatted_time

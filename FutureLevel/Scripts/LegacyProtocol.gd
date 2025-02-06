extends Node2D

@onready var time_panel: Panel = %TimePanel
@onready var upscale: Sprite2D = $TileMap/CityBack/Background/Upscale

func _ready():
	Global.legacy = self
	Engine.time_scale = 1.0

func complete_level():
	# Call stop() on the timer and get the formatted time
	%TimePanel.stop()
	var formatted_time = %TimePanel.get_time_formated()  # Now it will call the stop function from the Panel script
	GameManager.update_quickest_time(formatted_time)  # Pass the formatted time to the GameManager
	GameManager.save_data()  # Save the game data

func level_time() -> String: 
	%TimePanel.stop()
	var formatted_time = %TimePanel.get_time_formated()
	return formatted_time

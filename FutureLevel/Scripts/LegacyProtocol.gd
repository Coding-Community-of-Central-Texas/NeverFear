extends Node2D

@onready var time_panel: Panel = %TimePanel


func _ready():
	Global.legacy = self
	if DisplayServer.is_touchscreen_available() and OS.has_feature("Andriod"):
		get_viewport().screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	else:
		return

func complete_level():
	# Call stop() on the timer and get the formatted time
	var formatted_time = %TimePanel.stop()  # Now it will call the stop function from the Panel script
	GameManager.update_quickest_time(formatted_time)  # Pass the formatted time to the GameManager
	GameManager.save_data()  # Save the game data

func end():
	const WIN = preload("res://Scenes/WinScreen.tscn")
	var new_win = WIN.instantiate()
	add_child(new_win)
	complete_level()  # Complete the level

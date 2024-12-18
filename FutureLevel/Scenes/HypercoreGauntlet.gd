extends Node2D

@onready var survivor: CharacterBody2D = $Survivor
@onready var time_panel: Panel = %TimePanel


func _ready() -> void:
	Global.gauntlet = self

func _on_scene_transition() -> void:
	GameManager.reset_scene_kills()



func time_survived():
	# Call stop() on the timer and get the formatted time
	var formatted_time = %TimePanel.get_time_formated()  # Now it will call the stop function from the Panel script
	GameManager.update_longest_survival(formatted_time)  # Pass the formatted time to the GameManager
	GameManager.save_data()  # Save the game data

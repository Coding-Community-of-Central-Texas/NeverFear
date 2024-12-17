extends Node2D

@onready var survivor: CharacterBody2D = $Survivor
@onready var time_panel: Panel = $CanvasLayer/TimePanel
@onready var final_time: Label = $DeathndSpawn/FinalTime


func _on_scene_transition() -> void:
	GameManager.reset_scene_kills()

func finalize_time():
	var formated_time = time_panel.get_time_formated()
	if survivor._die():
		time_panel.paused = false
		final_time.visible = true 
		final_time.text = "Survive Time: %" % formated_time

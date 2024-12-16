extends Node2D

@onready var survivor: CharacterBody2D = $Survivor
@onready var final_time: Label = $FinalTime
@onready var time_panel: Panel = $CanvasLayer/TimePanel


func _on_scene_transition() -> void:
	GameManager.reset_scene_kills()

func finalize_time():
	var formated_time = time_panel.get_time_formated()
	if survivor._die():
		final_time.visible = true 
		final_time.text = "Survive Time: %" % formated_time

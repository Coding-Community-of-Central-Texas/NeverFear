extends Marker2D

@onready var timer: Timer = $Timer
@onready var marker_1: Marker2D = $Marker1




func _on_timer_timeout() -> void:
	spawn_wave()



func spawn_wave():
	const DROID  = preload("res://Scenes/DriodLegacy.tscn")
	const BYTE = preload("res://Scenes/OneHit.tscn")
	var new_byte = BYTE.instantiate()
	var new_droid = DROID.instantiate()
	new_byte.position = global_position
	new_droid.position = marker_1.global_position
	get_tree().current_scene.add_child(new_byte)
	get_tree().current_scene.add_child(new_droid) 

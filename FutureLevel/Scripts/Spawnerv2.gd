extends Marker2D

@onready var timer: Timer = $Timer
@onready var marker_1: Marker2D = $Marker1
@export var spawn_intervals: Array = [2.5, 1.5, 1.0, 0.8, 0.5]




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





func _on_survivor_rank_changed(rank_index: int) -> void:
	if rank_index >= 0 and rank_index < spawn_intervals.size():
		timer.wait_time = spawn_intervals[rank_index]
		print("Spawner updated: Rank =", rank_index, "New wait_time =", timer.wait_time)

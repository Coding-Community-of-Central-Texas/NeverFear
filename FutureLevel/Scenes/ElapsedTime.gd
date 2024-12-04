extends Label

func _process(delta: float) -> void:
	text = "Elapsed Time: %d" % Global.legacy.start_time

extends Label



func _process(_delta: float) -> void:
	text = "LIVES: %d" % Global.lives
	if Global.lives <= 1:
		self.modulate = Color(1, 0, 0)  # Set to red
		await get_tree().create_timer(0.5).timeout  # Wait for 0.1 seconds
		self.modulate = Color(1, 1, 1)  # Reset to normal
		return
	

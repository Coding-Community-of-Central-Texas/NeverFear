extends Control


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_hero_input() -> void:
	accept_event()

func _on_joystick_joystick_input() -> void:
	_on_hero_input()

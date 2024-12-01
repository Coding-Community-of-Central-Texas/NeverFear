extends Node2D

@onready var timer: Timer = $Timer

func _on_body_entered(body):
	if body.is_in_group("player"):
		timer.start()
		print("spawning")

func _on_body_exited(body):
	if body.is_in_group("player"):
		timer.stop()
		print("stopted spawning")



func _on_timer_timeout() -> void:
	const BYTE = preload("res://Scenes/OneHit.tscn")
	var new_byte = BYTE.instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_byte.position = %PathFollow2D.position
	add_child(new_byte)

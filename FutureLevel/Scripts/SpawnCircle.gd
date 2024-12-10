extends Node2D



@onready var timer: Timer = $Timer


func _ready() -> void:
	timer.start()

func _on_timer_timeout() -> void:
	spawn_wave()


func spawn_wave():
	const DROID  = preload("res://Scenes/DriodLegacy.tscn")
	const BYTE = preload("res://Scenes/OneHit.tscn")
	var new_byte = BYTE.instantiate()
	var new_droid = DROID.instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_droid.position = %PathFollow2D.position
	
	%PathFollow2D.progress_ratio += 0.1  # Adjust this value for desired spacing
	if %PathFollow2D.progress_ratio > 1.0:
		%PathFollow2D.progress_ratio -= 1.0  # Wrap around if it exceeds 1.0
		new_byte.position = %PathFollow2D.position
	new_byte.position = %PathFollow2D.position
	add_child(new_byte)
	add_child(new_droid) 

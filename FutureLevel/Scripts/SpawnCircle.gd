extends Path2D


@onready var timer: Timer = $Timer
@onready var queue_free_timer: Timer = $QueueFreeTimer


func _ready() -> void:
	timer.start()

func _on_timer_timeout() -> void:
	print("spawning")
	spawn_wave()
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
	get_tree().current_scene.add_child(new_byte)
	get_tree().current_scene.add_child(new_droid) 


func _on_queue_free_timer_timeout() -> void:
	print("free!")
	queue_free()

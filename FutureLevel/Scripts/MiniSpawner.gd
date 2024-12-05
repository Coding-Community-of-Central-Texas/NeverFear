extends Node2D

@onready var timer: Timer = $Timer

func _on_body_entered(body):
	if body.is_in_group("player"):
		timer.start()


func spawn_bosses():
	const DROID  = preload("res://Scenes/DriodLegacy.tscn")
	const BYTE = preload("res://Scenes/OneHit.tscn")
	var new_byte = BYTE.instantiate()
	var new_droid = DROID.instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_droid.position = %PathFollow2D.position
	new_byte.position = %PathFollow2D.position
	add_child(new_byte)
	add_child(new_droid)


func _on_timer_timeout() -> void:
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()

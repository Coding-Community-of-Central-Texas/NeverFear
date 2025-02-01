extends Node2D

@onready var timer: Timer = $Timer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

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
	get_tree().current_scene.add_child(new_byte)
	get_tree().current_scene.add_child(new_droid)


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
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()
	spawn_bosses()
	await get_tree().create_timer(2.0).timeout
	queue_free()

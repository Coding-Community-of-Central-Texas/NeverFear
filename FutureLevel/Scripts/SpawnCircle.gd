extends Path2D

const LEGACY_DROID := preload("res://Scenes/DriodLegacy.tscn")
const LEGACY_BYTE := preload("res://Scenes/OneHit.tscn")
const GAUNTLET_DROID := preload("res://Scenes/DriodGauntlet.tscn")
const GAUNTLET_BYTE := preload("res://Scenes/OneHitGuantlet.tscn")

@onready var timer: Timer = $Timer
@onready var queue_free_timer: Timer = $QueueFreeTimer


func _ready() -> void:
	timer.start()

func _on_timer_timeout() -> void:
	print("spawning")
	spawn_wave()
	spawn_wave()

func spawn_wave():
	var pool_manager := _get_pool_manager()
	var droid_scene := GAUNTLET_DROID if pool_manager != null else LEGACY_DROID
	var byte_scene := GAUNTLET_BYTE if pool_manager != null else LEGACY_BYTE

	%PathFollow2D.progress_ratio = randf()
	var droid_position: Vector2 = %PathFollow2D.global_position
	
	%PathFollow2D.progress_ratio += 0.1  # Adjust this value for desired spacing
	if %PathFollow2D.progress_ratio > 1.0:
		%PathFollow2D.progress_ratio -= 1.0  # Wrap around if it exceeds 1.0
	var byte_position: Vector2 = %PathFollow2D.global_position

	_spawn_enemy(droid_scene, droid_position, pool_manager)
	_spawn_enemy(byte_scene, byte_position, pool_manager)


func _on_queue_free_timer_timeout() -> void:
	print("free!")
	queue_free()

func _spawn_enemy(enemy_scene: PackedScene, spawn_position: Vector2, pool_manager: Node) -> Node2D:
	if pool_manager != null and pool_manager.has_method("spawn_enemy"):
		return pool_manager.call("spawn_enemy", enemy_scene, spawn_position) as Node2D

	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		return null

	enemy.global_position = spawn_position
	get_tree().current_scene.add_child(enemy)
	return enemy

func _get_pool_manager() -> Node:
	return get_tree().get_first_node_in_group("survival_pool_manager")

extends Marker2D

const DROID := preload("res://Scenes/DriodGauntlet.tscn")
const BYTE := preload("res://Scenes/OneHitGuantlet.tscn")

@onready var timer: Timer = $Timer
@onready var marker_1: Marker2D = $Marker1
@export var spawn_intervals: Array = [2.0, 1.0, 0.9, 0.7, 0.2]

func _on_timer_timeout() -> void:
	spawn_wave()

func spawn_wave():
	_spawn_enemy(BYTE, global_position)
	_spawn_enemy(DROID, marker_1.global_position)

func _on_survivor_rank_changed(rank_index: int) -> void:
	if rank_index >= 0 and rank_index < spawn_intervals.size():
		timer.wait_time = spawn_intervals[rank_index]

func _spawn_enemy(enemy_scene: PackedScene, spawn_position: Vector2) -> Node2D:
	var pool_manager := _get_pool_manager()
	if pool_manager != null and pool_manager.has_method("spawn_enemy"):
		return pool_manager.call("spawn_enemy", enemy_scene, spawn_position) as Node2D

	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		return null

	enemy.visible = false
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_position
	if enemy is CharacterBody2D:
		var body := enemy as CharacterBody2D
		body.velocity = Vector2.ZERO
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	if enemy.has_method("start_spawn_timer"):
		enemy.call("start_spawn_timer")
	else:
		enemy.visible = true
	return enemy

func _get_pool_manager() -> Node:
	return get_tree().get_first_node_in_group("survival_pool_manager")

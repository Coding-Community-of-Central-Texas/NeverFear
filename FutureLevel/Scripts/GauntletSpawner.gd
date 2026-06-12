# file: scripts/spawner.gd
extends Marker2D

@onready var timer: Timer = $Timer

@onready var marker_1: Marker2D = $Marker1
@onready var marker_2: Marker2D = $Marker2
@onready var marker_3: Marker2D = $Marker3
@onready var marker_4: Marker2D = $Marker4
@onready var marker_5: Marker2D = $Marker5
@onready var marker_6: Marker2D = $Marker6
@onready var marker_7: Marker2D = $Marker7
@onready var marker_8: Marker2D = $Marker8
@onready var marker_9: Marker2D = $Marker9
@onready var marker_10: Marker2D = $Marker10
@onready var marker_11: Marker2D = $Marker11
@onready var marker_12: Marker2D = $Marker12
@onready var marker_13: Marker2D = $Marker13
@onready var marker_14: Marker2D = $Marker14

@export var spawn_intervals: Array[float] = [2.0, 1.5, 1.2, 1.0, 0.8]
@export var max_enemies_per_wave: Array[int] = [5, 7, 9, 11, 20]
@export var extra_enemies_per_wave: int = 3
@export var enemy_scenes: Array[PackedScene] = [
	preload("res://Scenes/DriodGauntlet.tscn"),
	preload("res://Scenes/OneHitGuantlet.tscn"),
]

@export var spawn_spread: float = 16.0

var spawn_markers: Array[Marker2D] = []
var current_wave: int = 1
var spawning_enabled: bool = false

func _ready() -> void:
	add_to_group("gauntlet_spawner")

	spawn_markers = [
		marker_1, marker_2, marker_3, marker_4, marker_5, marker_6, marker_7,
		marker_8, marker_9, marker_10, marker_11, marker_12, marker_13, marker_14
	]

	randomize()
	_apply_wave_settings()
	timer.stop()

func _on_timer_timeout() -> void:
	spawn_wave()

func start_wave(wave_number: int) -> void:
	current_wave = max(wave_number, 1)
	spawning_enabled = true
	_apply_wave_settings()
	timer.stop()
	spawn_wave()
	timer.start()

func stop_spawning() -> void:
	spawning_enabled = false
	timer.stop()

func spawn_wave() -> void:
	if not spawning_enabled:
		return

	if spawn_markers.is_empty() or enemy_scenes.is_empty():
		return

	var enemy_count: int = _get_enemy_count()

	# Use a shuffled copy so markers are spread out first before reusing any.
	var available_markers: Array[Marker2D] = spawn_markers.duplicate()
	available_markers.shuffle()

	for i in range(enemy_count):
		var enemy_scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]

		var spawn_marker: Marker2D

		if i < available_markers.size():
			spawn_marker = available_markers[i]
		else:
			spawn_marker = spawn_markers[randi() % spawn_markers.size()]

		var spawn_offset := Vector2(
			randf_range(-spawn_spread, spawn_spread),
			randf_range(-spawn_spread, spawn_spread)
		)

		var spawn_pos: Vector2 = spawn_marker.global_position + spawn_offset

		var enemy := _spawn_enemy(enemy_scene, spawn_pos)
		if enemy == null:
			continue

func _spawn_enemy(enemy_scene: PackedScene, spawn_pos: Vector2) -> Node2D:
	var pool_manager := _get_pool_manager()
	if pool_manager != null and pool_manager.has_method("spawn_enemy"):
		return pool_manager.call("spawn_enemy", enemy_scene, spawn_pos) as Node2D

	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	if enemy == null:
		return null

	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_pos

	if enemy is CharacterBody2D:
		var body := enemy as CharacterBody2D
		body.velocity = Vector2.ZERO

	return enemy

func _get_pool_manager() -> Node:
	return get_tree().get_first_node_in_group("survival_pool_manager")

func _apply_wave_settings() -> void:
	if spawn_intervals.is_empty():
		return

	var wave_index: int = clamp(current_wave - 1, 0, spawn_intervals.size() - 1)
	timer.wait_time = spawn_intervals[wave_index]

func _get_enemy_count() -> int:
	if max_enemies_per_wave.is_empty():
		return 0

	var wave_index: int = current_wave - 1

	if wave_index < max_enemies_per_wave.size():
		return max_enemies_per_wave[wave_index]

	var last_enemy_count: int = max_enemies_per_wave[max_enemies_per_wave.size() - 1]
	var extra_waves: int = wave_index - max_enemies_per_wave.size() + 1
	return last_enemy_count + extra_waves * extra_enemies_per_wave

func _on_survivor_rank_changed(_rank_index: int) -> void:
	pass

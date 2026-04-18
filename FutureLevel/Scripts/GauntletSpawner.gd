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
@export var enemy_scenes: Array[PackedScene] = [
	preload("res://Scenes/DriodGauntlet.tscn"),
	preload("res://Scenes/OneHitGuantlet.tscn"),
]

var spawn_markers: Array[Marker2D] = []
var current_rank: int = 0

func _ready() -> void:
	spawn_markers = [
		marker_1, marker_2, marker_3, marker_4, marker_5, marker_6, marker_7,
		marker_8, marker_9, marker_10, marker_11, marker_12, marker_13, marker_14
	]
	if timer.is_stopped():
		timer.start()

func _on_timer_timeout() -> void:
	spawn_wave()

func spawn_wave() -> void:
	if spawn_markers.is_empty() or enemy_scenes.is_empty():
		return

	var rank_index: int = clamp(current_rank, 0, max_enemies_per_wave.size() - 1)
	var enemy_count: int = max_enemies_per_wave[rank_index]

	for i in range(enemy_count):
		# Ensure typed values; avoid Variant inference.
		var enemy_scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
		var enemy: Node2D = enemy_scene.instantiate() as Node2D

		# Parent first, then place using global coords.
		get_tree().current_scene.add_child(enemy)

		var spawn_marker: Marker2D = spawn_markers[randi() % spawn_markers.size()]
		enemy.global_position = spawn_marker.global_position

		# Reset motion safely to prevent pooling drift.
		if enemy is CharacterBody2D:
			(enemy as CharacterBody2D).velocity = Vector2.ZERO

func _on_survivor_rank_changed(rank_index: int) -> void:
	current_rank = clamp(rank_index, 0, spawn_intervals.size() - 1)
	timer.wait_time = float(spawn_intervals[current_rank])

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

@export var spawn_intervals: Array = [2.0, 1.5, 1.2, 1.0, 0.8]  # More difficulty levels
@export var max_enemies_per_wave: Array = [5, 7, 9, 11, 20]  # Increase enemy count per rank
@export var enemy_scenes: Array[PackedScene] = [
	preload("res://Scenes/DriodGauntlet.tscn"),
	preload("res://Scenes/OneHitGuantlet.tscn"),
]

var spawn_markers: Array[Marker2D] = []
var current_rank: int = 0

func _ready():
	# Manually add all markers to the list
	spawn_markers = [
		marker_1, marker_2, marker_3, marker_4, marker_5, marker_6, marker_7, 
		marker_8, marker_9, marker_10, marker_11, marker_12, marker_13, marker_14
	]

func _on_timer_timeout() -> void:
	spawn_wave()

func spawn_wave():
	var enemy_count = max_enemies_per_wave[current_rank]  # Get enemy count for current rank
	
	for i in range(enemy_count):
		var enemy_scene = enemy_scenes.pick_random()  # Pick a random enemy
		var new_enemy = enemy_scene.instantiate()

		# Select a random spawn marker from the manually defined list
		var spawn_marker = spawn_markers.pick_random()
		new_enemy.position = spawn_marker.global_position  # Use local position

		# Add the enemy to the same parent as the spawner (ensures correct hierarchy)
		get_tree().current_scene.add_child(new_enemy)

func _on_survivor_rank_changed(rank_index: int) -> void:
	if rank_index >= 0 and rank_index < spawn_intervals.size():
		current_rank = rank_index  # Update difficulty rank
		timer.wait_time = spawn_intervals[rank_index]  # Adjust spawn rate

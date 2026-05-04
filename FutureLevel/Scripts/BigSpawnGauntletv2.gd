extends Marker2D

const ROBBIE = preload("res://Scenes/GauntletThreeHitter.tscn")
const TANK = preload("res://Scenes/TankGauntlet.tscn")

enum CharacterType {
	ROBBIE,
	TANK
}


@onready var timer: Timer = $Timer
@onready var marker_1: Marker2D = $Marker1
@export var spawn_intervals: Array[float] = [5.0, 4.0, 3.0, 2.0, 1.0]
@export var max_enemies_per_wave: Array[int] = [1, 1, 2, 2, 3]
@export var extra_enemies_per_wave: int = 1
@export var spawn_spread: float = 24.0

var current_wave: int = 1
var spawning_enabled: bool = false

func _ready() -> void:
	add_to_group("gauntlet_spawner")
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

func spawn_wave():
	if not spawning_enabled:
		return

	# Randomly select the characters to spawn
	var spawn_list = []

	for i in range(_get_enemy_count()):
		spawn_list.append(get_random_character(CharacterType.ROBBIE, CharacterType.TANK))

	# Iterate through the spawn list and spawn characters
	for character in spawn_list:  
		var instance = character.instantiate()
		instance.position = marker_1.global_position + Vector2(
			randf_range(-spawn_spread, spawn_spread),
			randf_range(-spawn_spread, spawn_spread)
		)
		get_tree().current_scene.add_child(instance)
		# Optional: Adjust spacing if needed

func get_random_character(_type1: int, _type2: int) -> PackedScene:
	return ROBBIE if randi() % 2 == 0 else TANK 

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

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
	var spawn_data := _get_wave_spawn_data()
	for character in spawn_list:  
		var spawn_pos: Vector2 = marker_1.global_position + Vector2(
			randf_range(-spawn_spread, spawn_spread),
			randf_range(-spawn_spread, spawn_spread)
		)
		_spawn_enemy(character, spawn_pos, spawn_data)
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

func _spawn_enemy(enemy_scene: PackedScene, spawn_pos: Vector2, data: Dictionary = {}) -> Node2D:
	var pool_manager := _get_pool_manager()
	if pool_manager != null and pool_manager.has_method("spawn_enemy"):
		return pool_manager.call("spawn_enemy", enemy_scene, spawn_pos, data) as Node2D

	var instance := enemy_scene.instantiate() as Node2D
	if instance == null:
		return null
	instance.visible = false
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().current_scene.add_child(instance)
	instance.global_position = spawn_pos
	if instance is CharacterBody2D:
		var body := instance as CharacterBody2D
		body.velocity = Vector2.ZERO
	if instance.has_method("apply_wave_scaling"):
		instance.call("apply_wave_scaling", data)
	instance.process_mode = Node.PROCESS_MODE_INHERIT
	if instance.has_method("start_spawn_timer"):
		instance.call("start_spawn_timer")
	else:
		instance.visible = true
	return instance

func _get_pool_manager() -> Node:
	return get_tree().get_first_node_in_group("survival_pool_manager")

func _get_wave_spawn_data() -> Dictionary:
	var gauntlet_node = Global.gauntlet
	if gauntlet_node is Node and is_instance_valid(gauntlet_node) and gauntlet_node.has_method("get_enemy_wave_scaling"):
		var scaling = gauntlet_node.call("get_enemy_wave_scaling", current_wave)
		if scaling is Dictionary:
			return scaling
	return {}

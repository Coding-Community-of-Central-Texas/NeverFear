extends Path2D

const ROBBIE = preload("res://Scenes/GauntletThreeHitter.tscn")
const TANK = preload("res://Scenes/TankGauntlet.tscn")

enum CharacterType {
	ROBBIE,
	TANK
}

@onready var big_timer: Timer = $BigTimer
@onready var queue_free_timer: Timer = $QueueFreeTimer

var spawning_enabled: bool = false
var current_wave: int = 1

func _ready() -> void:
	add_to_group("gauntlet_spawner")
	big_timer.stop()

func _on_timer_timeout() -> void:
	spawn_wave()

func start_wave(wave_number: int) -> void:
	current_wave = max(wave_number, 1)
	spawning_enabled = true
	big_timer.stop()
	spawn_wave()
	big_timer.start()

func stop_spawning() -> void:
	spawning_enabled = false
	big_timer.stop()

func spawn_wave():
	if not spawning_enabled:
		return

	# Randomly select the characters to spawn
	var spawn_list = [
		get_random_character(CharacterType.ROBBIE, CharacterType.TANK)
	]
	# Iterate through the spawn list and spawn characters
	var spawn_data := _get_wave_spawn_data()
	for character in spawn_list:
		%PathFollow2D.progress_ratio = randf()  
		_spawn_enemy(character, %PathFollow2D.global_position, spawn_data)
		# Optional: Adjust spacing if needed
		%PathFollow2D.progress_ratio += 0.1
		if %PathFollow2D.progress_ratio > 1.0:
			%PathFollow2D.progress_ratio -= 1.0

func get_random_character(_type1: int, _type2: int) -> PackedScene:
	return ROBBIE if randi() % 2 == 0 else TANK 


func _on_queue_free_timer_timeout() -> void:
	print("quefree!")
	queue_free()

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

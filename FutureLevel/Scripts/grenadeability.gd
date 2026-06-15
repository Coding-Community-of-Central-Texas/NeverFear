extends Node


@export var grenade_scene: PackedScene
@export var cooldown: float = 2.0
@export var throw_force: float = 900.0

signal cooldown_started(duration: float)
signal cooldown_ready()

var _cooling_down: bool = false
var _cd_timer: Timer

func _ready() -> void:
	_cd_timer = Timer.new()
	_cd_timer.one_shot = true
	_cd_timer.wait_time = cooldown
	_cd_timer.timeout.connect(_on_cd_timeout)
	add_child(_cd_timer)

func can_throw() -> bool:
	return not _cooling_down and grenade_scene != null

func try_throw(from_global_pos: Vector2, direction: Vector2) -> bool:
	if not can_throw():
		return false
	if direction == Vector2.ZERO:
		return false

	var pool_manager := _get_pool_manager()
	if pool_manager != null and pool_manager.has_method("spawn_grenade"):
		var grenade: Node = pool_manager.call("spawn_grenade", from_global_pos, direction, throw_force)
		if grenade == null:
			return false
		_start_cooldown()
		return true

	var grenade: Node2D = grenade_scene.instantiate() as Node2D
	if grenade == null:
		return false

	grenade.global_position = from_global_pos
	get_tree().current_scene.add_child(grenade)
	if grenade.has_method("throw"):
		grenade.call("throw", direction, throw_force)
	_start_cooldown()
	return true

func _get_pool_manager() -> Node:
	return get_tree().get_first_node_in_group("survival_pool_manager")

func _start_cooldown() -> void:
	_cooling_down = true
	_cd_timer.stop()
	_cd_timer.wait_time = cooldown
	_cd_timer.start()
	emit_signal("cooldown_started", cooldown)

func _on_cd_timeout() -> void:
	_cooling_down = false
	emit_signal("cooldown_ready")

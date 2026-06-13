extends Node
class_name ObjectPool

signal pool_exhausted(scene_path: String)

@export var scene: PackedScene
@export var prewarm_count: int = 0
@export var max_size: int = 0

var _inactive: Array[Node] = []
var _active: Array[Node] = []
var _created_count: int = 0
var _warned_exhausted := false

func setup(pool_scene: PackedScene, initial_size: int = 0, limit: int = 0) -> void:
	scene = pool_scene
	prewarm_count = maxi(initial_size, 0)
	max_size = maxi(limit, 0)
	prewarm(prewarm_count)

func prewarm(count: int) -> void:
	if scene == null:
		return

	for _index in range(maxi(count, 0)):
		if max_size > 0 and _created_count >= max_size:
			return

		var instance := _create_instance()
		if instance == null:
			return
		_return_prepared_instance(instance)

func get_instance(spawn_position: Vector2 = Vector2.ZERO, data: Dictionary = {}) -> Node:
	var instance: Node = null

	while not _inactive.is_empty() and instance == null:
		instance = _inactive.pop_back()
		if instance == null or not is_instance_valid(instance):
			instance = null

	if instance == null:
		if max_size > 0 and _created_count >= max_size:
			_warn_exhausted()
			return null
		instance = _create_instance()

	if instance == null:
		return null

	_apply_basic_inactive_state(instance)

	if instance.get_parent() == null:
		add_child(instance)

	if not _active.has(instance):
		_active.append(instance)

	_prepare_instance_for_spawn(instance, spawn_position)

	if instance.has_method("activate"):
		instance.call("activate", spawn_position, data)
	else:
		_apply_basic_active_state(instance, spawn_position)

	return instance

func return_instance(instance: Node) -> void:
	if instance == null or not is_instance_valid(instance):
		return

	_active.erase(instance)
	if _inactive.has(instance):
		return

	if instance.get_parent() == null:
		add_child(instance)

	_inactive.append(instance)

func get_active_count() -> int:
	return _active.size()

func get_available_count() -> int:
	return _inactive.size()

func get_created_count() -> int:
	return _created_count

func _create_instance() -> Node:
	if scene == null:
		return null

	var instance := scene.instantiate()
	if instance == null:
		return null

	_created_count += 1
	_prepare_pooled_instance(instance)
	_apply_basic_inactive_state(instance)
	add_child(instance)
	return instance

func _prepare_instance_for_spawn(instance: Node, spawn_position: Vector2) -> void:
	if instance is Node2D:
		(instance as Node2D).global_position = spawn_position
	if instance is CharacterBody2D:
		(instance as CharacterBody2D).velocity = Vector2.ZERO

func _prepare_pooled_instance(instance: Node) -> void:
	instance.set_meta("pooled", true)

	if instance.has_method("set_pooled"):
		instance.call("set_pooled", true)

	if instance.has_signal("request_pool_return"):
		var callable := Callable(self, "_on_instance_requested_return")
		if not instance.is_connected("request_pool_return", callable):
			instance.connect("request_pool_return", callable)

func _return_prepared_instance(instance: Node) -> void:
	if instance.has_method("deactivate"):
		instance.call("deactivate", false)
	else:
		_apply_basic_inactive_state(instance)
	return_instance(instance)

func _on_instance_requested_return(instance: Node) -> void:
	return_instance(instance)

func _apply_basic_active_state(instance: Node, spawn_position: Vector2) -> void:
	if instance is Node2D:
		(instance as Node2D).global_position = spawn_position
	if instance is CanvasItem:
		(instance as CanvasItem).visible = true
	instance.process_mode = Node.PROCESS_MODE_INHERIT

func _apply_basic_inactive_state(instance: Node) -> void:
	if instance is CanvasItem:
		(instance as CanvasItem).visible = false
	instance.process_mode = Node.PROCESS_MODE_DISABLED

func _warn_exhausted() -> void:
	if _warned_exhausted:
		return

	_warned_exhausted = true
	var scene_path := ""
	if scene != null:
		scene_path = scene.resource_path
	pool_exhausted.emit(scene_path)

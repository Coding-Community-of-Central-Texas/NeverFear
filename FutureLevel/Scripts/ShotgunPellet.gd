extends Area2D

signal request_pool_return(instance: Node)

@export var speed: float = 1800.0
@export var travel_range: float = 360.0
@export var damage: int = 3
@export var spread_ramp_distance: float = 150.0
@export var bullet_pen: float = 0.04

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var trail: CPUParticles2D = $Trail

var travelled_distance: float = 0.0
var base_rotation: float = 0.0
var target_rotation: float = 0.0
var configured := false
var hit_started := false
var active := true
var pooled := false
var _base_speed: float = 0.0
var _lifecycle_id := 0

func configure(start_rotation: float, spread_offset: float, speed_multiplier: float = 1.0) -> void:
	if _base_speed <= 0.0:
		_base_speed = speed

	base_rotation = start_rotation
	target_rotation = start_rotation + spread_offset
	speed = _base_speed * speed_multiplier
	global_rotation = start_rotation
	configured = true

func _ready() -> void:
	if _base_speed <= 0.0:
		_base_speed = speed
	if not configured:
		base_rotation = global_rotation
		target_rotation = global_rotation

func set_pooled(value: bool) -> void:
	pooled = value

func activate(spawn_position: Vector2, data: Dictionary = {}) -> void:
	_lifecycle_id += 1
	active = true
	hit_started = false
	configured = false
	travelled_distance = 0.0
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_physics_process(true)
	global_position = spawn_position
	global_rotation = float(data.get("rotation", global_rotation))
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", false)
	if trail:
		trail.emitting = true
		trail.restart()

	var spread_offset := float(data.get("spread_offset", 0.0))
	var speed_multiplier := float(data.get("speed_multiplier", 1.0))
	configure(global_rotation, spread_offset, speed_multiplier)

func deactivate(return_to_pool: bool = true) -> void:
	if not active and return_to_pool:
		return

	_lifecycle_id += 1
	active = false
	hit_started = false
	travelled_distance = 0.0
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)
	process_mode = Node.PROCESS_MODE_DISABLED
	if _base_speed > 0.0:
		speed = _base_speed
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)
	if trail:
		trail.emitting = false

	if pooled:
		if return_to_pool:
			request_pool_return.emit(self)
	elif return_to_pool:
		queue_free()

func _physics_process(delta: float) -> void:
	if not active:
		return

	var spread_progress := 1.0
	if spread_ramp_distance > 0.0:
		spread_progress = clampf(travelled_distance / spread_ramp_distance, 0.0, 1.0)

	var eased_progress := spread_progress * spread_progress * (3.0 - 2.0 * spread_progress)
	var current_rotation := lerp_angle(base_rotation, target_rotation, eased_progress)
	var direction := Vector2.RIGHT.rotated(current_rotation)

	global_rotation = current_rotation
	position += direction * speed * delta

	travelled_distance += speed * delta
	if travelled_distance > travel_range:
		deactivate()

func _on_body_entered(body: Node2D) -> void:
	if not active or hit_started:
		return

	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.call("take_damage", damage)

	hit_started = true
	set_deferred("monitoring", false)
	var lifecycle_id := _lifecycle_id
	await get_tree().create_timer(bullet_pen).timeout
	if lifecycle_id == _lifecycle_id:
		deactivate()

extends Area2D

signal request_pool_return(instance: Node)

const SPEED = 2000.0
const RANGE = 500.0

@export var bullet_pen = 0.07

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var trail: CPUParticles2D = $Trail

var travelled_distance = 0.0
var active := true
var pooled := false
var hit_started := false
var _lifecycle_id := 0

func set_pooled(value: bool) -> void:
	pooled = value

func activate(spawn_position: Vector2, data: Dictionary = {}) -> void:
	_lifecycle_id += 1
	active = true
	hit_started = false
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
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)
	if trail:
		trail.emitting = false

	if pooled:
		if return_to_pool:
			request_pool_return.emit(self)
	elif return_to_pool:
		queue_free()

func _physics_process(delta):
	if not active:
		return
	
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * SPEED * delta
	
	travelled_distance += SPEED * delta
	if travelled_distance > RANGE:
		deactivate()

func _on_body_entered(body: CharacterBody2D) -> void:
	if not active or hit_started:
		return

	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(5)
	for_bullet_pen()

func for_bullet_pen():
	hit_started = true
	set_deferred("monitoring", false)
	var lifecycle_id := _lifecycle_id
	await get_tree().create_timer(bullet_pen).timeout
	if lifecycle_id == _lifecycle_id:
		deactivate()

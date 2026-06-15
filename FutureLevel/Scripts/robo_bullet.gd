extends Area2D

signal request_pool_return(instance: Node)

var travelled_distance = 0.0
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
var velocity = Vector2.ZERO
var active := true
var pooled := false


func _ready():
	%AnimatedSprite2D.play("shoot")
	%AnimatedSprite2D.flip_h

func set_pooled(value: bool) -> void:
	pooled = value

func activate(spawn_position: Vector2, data: Dictionary = {}) -> void:
	active = true
	travelled_distance = 0.0
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_physics_process(true)
	global_position = spawn_position
	rotation = float(data.get("rotation", rotation))
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", false)
	if animated_sprite_2d:
		animated_sprite_2d.visible = true
		animated_sprite_2d.play("shoot")

	var direction: Vector2 = data.get("direction", Vector2.ZERO)
	if direction != Vector2.ZERO:
		set_direction(direction)
	else:
		velocity = Vector2.ZERO

func deactivate(return_to_pool: bool = true) -> void:
	if not active and return_to_pool:
		return

	active = false
	travelled_distance = 0.0
	velocity = Vector2.ZERO
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)
	if animated_sprite_2d:
		animated_sprite_2d.stop()

	if pooled:
		if return_to_pool:
			request_pool_return.emit(self)
	elif return_to_pool:
		queue_free()

func _physics_process(delta):
	if not active:
		return

	const RANGE = 678.0
	const SPEED = 180.0
	
	var displacement = velocity * delta
	position += displacement
	
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * SPEED * delta
	
	
	travelled_distance += displacement.length()
	if travelled_distance > RANGE:
		deactivate()

func _on_body_entered(body) -> void:
	if not active:
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(10)
		deactivate()

func set_direction(direction: Vector2):
	velocity = direction.normalized() * 170

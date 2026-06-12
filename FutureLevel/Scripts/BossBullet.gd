extends Area2D

signal request_pool_return(instance: Node)

@export var speed = 400  # Speed of the bullet
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var collision_shape = $CollisionShape2D
var velocity = Vector2(0, -speed)
var active := true
var pooled := false

func _ready():
	sprite_2d.play("lava")

func set_pooled(value: bool) -> void:
	pooled = value

func activate(spawn_position: Vector2, data: Dictionary = {}) -> void:
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_process(true)
	global_position = spawn_position
	velocity = data.get("velocity", Vector2(0, -speed))
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if sprite_2d:
		sprite_2d.play("lava")

func deactivate(return_to_pool: bool = true) -> void:
	if not active and return_to_pool:
		return

	active = false
	visible = false
	velocity = Vector2.ZERO
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_process(false)
	process_mode = Node.PROCESS_MODE_DISABLED
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if sprite_2d:
		sprite_2d.stop()

	if pooled:
		if return_to_pool:
			request_pool_return.emit(self)
	elif return_to_pool:
		queue_free()

func _process(delta):
	if not active:
		return

	position += velocity * delta

func _on_body_entered(body):
	if not active:
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(20)
	deactivate()

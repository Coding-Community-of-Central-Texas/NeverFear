extends Area2D

signal request_pool_return(instance: Node)

var travelled_distance = 0.0
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
var velocity = Vector2.ZERO
@onready var explosion: AnimatedSprite2D = %Explosion
@onready var missile: Sprite2D = $Missile
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

# Homing missile variables
@export var homing_duration = 3.0 # seconds to track the player
@export var turn_rate = 2.75 # radians per second
@export var missile_speed = 200.0
@export var damage = 25
@export var max_range = 678.0

var base_damage := -1
var homing_timer = 0.0
var is_homing = true
var is_exploding = false
var active := true
var pooled := false
var _lifecycle_id := 0

func _ready():
	_ensure_base_damage()
	%AnimatedSprite2D.play("shoot")
	%AnimatedSprite2D.flip_h
	%Explosion.visible = false
	%Explosion.stop()
	homing_timer = homing_duration

func set_pooled(value: bool) -> void:
	pooled = value

func activate(spawn_position: Vector2, data: Dictionary = {}) -> void:
	_lifecycle_id += 1
	active = true
	travelled_distance = 0.0
	is_homing = true
	is_exploding = false
	homing_timer = homing_duration
	configure_damage_scale(float(data.get("damage_scale", 1.0)))
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_physics_process(true)
	global_position = spawn_position
	rotation = float(data.get("rotation", rotation))
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", false)
	if missile:
		missile.visible = true
	if animated_sprite_2d:
		animated_sprite_2d.visible = true
		animated_sprite_2d.play("shoot")
	if explosion:
		explosion.visible = false
		explosion.stop()

	var direction: Vector2 = data.get("direction", Vector2.ZERO)
	if direction != Vector2.ZERO:
		set_direction(direction)
	else:
		velocity = Vector2.RIGHT.rotated(rotation) * missile_speed

func deactivate(return_to_pool: bool = true) -> void:
	if not active and return_to_pool:
		return

	_lifecycle_id += 1
	active = false
	travelled_distance = 0.0
	is_homing = false
	is_exploding = false
	velocity = Vector2.ZERO
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)
	process_mode = Node.PROCESS_MODE_DISABLED
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)
	if animated_sprite_2d:
		animated_sprite_2d.stop()
	if explosion:
		explosion.visible = false
		explosion.stop()

	if pooled:
		if return_to_pool:
			request_pool_return.emit(self)
	elif return_to_pool:
		queue_free()

func _physics_process(delta):
	if not active:
		return

	if is_exploding:
		return

	if is_homing:
		homing_timer -= delta
		if homing_timer <= 0.0:
			is_homing = false

		if Global.player and is_instance_valid(Global.player):
			var to_player = (Global.player.global_position - global_position).normalized()
			_steer_toward(to_player, delta)

	var displacement = velocity * delta
	position += displacement
	
	# Point the missile in the direction of movement
	if velocity.length() > 0:
		rotation = velocity.angle()

	travelled_distance += displacement.length()
	if travelled_distance > max_range:
		missile_impact()

func _on_body_entered(body: Node2D) -> void:
	if not active:
		return

	if is_exploding:
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)

	missile_impact()

func missile_impact():
	if not active or is_exploding:
		return

	is_exploding = true
	is_homing = false
	velocity = Vector2.ZERO
	set_deferred("monitoring", false)
	collision_shape_2d.set_deferred("disabled", true)
	missile.visible = false
	%Explosion.visible = true
	%Explosion.frame = 0
	%Explosion.play("missile_impact")
	var lifecycle_id := _lifecycle_id
	await %Explosion.animation_finished
	if lifecycle_id == _lifecycle_id:
		deactivate()

func set_direction(direction: Vector2):
	velocity = direction.normalized() * missile_speed

func configure_damage_scale(scale: float) -> void:
	_ensure_base_damage()
	damage = maxi(1, int(round(float(base_damage) * maxf(scale, 0.1))))

func _ensure_base_damage() -> void:
	if base_damage < 0:
		base_damage = damage

func _steer_toward(target_direction: Vector2, delta: float) -> void:
	if target_direction == Vector2.ZERO:
		return

	var current_direction = velocity.normalized()
	if current_direction == Vector2.ZERO:
		current_direction = Vector2.RIGHT.rotated(rotation)

	var current_angle = current_direction.angle()
	var target_angle = target_direction.angle()
	var angle_delta = wrapf(target_angle - current_angle, -PI, PI)
	var max_turn = turn_rate * delta
	var next_angle = current_angle + clamp(angle_delta, -max_turn, max_turn)
	velocity = Vector2.RIGHT.rotated(next_angle) * missile_speed

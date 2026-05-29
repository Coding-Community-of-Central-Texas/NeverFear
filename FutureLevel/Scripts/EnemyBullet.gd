extends Area2D

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

var homing_timer = 0.0
var is_homing = true
var is_exploding = false

func _ready():
	%AnimatedSprite2D.play("shoot")
	%AnimatedSprite2D.flip_h
	%Explosion.visible = false
	%Explosion.stop()
	homing_timer = homing_duration

func _physics_process(delta):
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

func _on_body_entered(body: CharacterBody2D) -> void:
	if is_exploding:
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		missile_impact()

func missile_impact():
	if is_exploding:
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
	await %Explosion.animation_finished
	queue_free()

func set_direction(direction: Vector2):
	velocity = direction.normalized() * missile_speed

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

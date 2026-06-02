extends Area2D

@export var speed: float = 1800.0
@export var travel_range: float = 360.0
@export var damage: int = 3
@export var spread_ramp_distance: float = 150.0
@export var bullet_pen: float = 0.04

var travelled_distance: float = 0.0
var base_rotation: float = 0.0
var target_rotation: float = 0.0
var configured := false
var hit_started := false

func configure(start_rotation: float, spread_offset: float, speed_multiplier: float = 1.0) -> void:
	base_rotation = start_rotation
	target_rotation = start_rotation + spread_offset
	speed *= speed_multiplier
	global_rotation = start_rotation
	configured = true

func _ready() -> void:
	if not configured:
		base_rotation = global_rotation
		target_rotation = global_rotation

func _physics_process(delta: float) -> void:
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
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if hit_started:
		return

	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.call("take_damage", damage)

	hit_started = true
	set_deferred("monitoring", false)
	await get_tree().create_timer(bullet_pen).timeout
	queue_free()

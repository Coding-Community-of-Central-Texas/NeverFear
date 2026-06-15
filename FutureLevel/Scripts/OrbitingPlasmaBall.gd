extends Area2D

@export var orbit_radius: float = 54.0
@export var orbit_speed: float = 4.25
@export var damage: float = 5.0
@export var damage_interval: float = 0.35
@export var spin_speed: float = 7.0
@export var starting_angle: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $Plasmaball/AnimatedSprite2D

var _angle: float = 0.0
var _damage_cooldowns: Dictionary = {}

func _ready() -> void:
	set_orbit_angle(starting_angle)
	animated_sprite.play("default")

func _physics_process(delta: float) -> void:
	if _player_is_dead():
		visible = false
		monitoring = false
		return

	_angle = wrapf(_angle + orbit_speed * delta, 0.0, TAU)
	_update_orbit_position()
	rotation += spin_speed * delta

	_tick_damage_cooldowns(delta)
	_damage_overlapping_enemies()

func set_orbit_angle(angle: float) -> void:
	starting_angle = angle
	_angle = wrapf(angle, 0.0, TAU)
	_update_orbit_position()

func _update_orbit_position() -> void:
	position = Vector2(cos(_angle), sin(_angle)) * orbit_radius

func _player_is_dead() -> bool:
	var parent_node := get_parent()
	return parent_node != null and parent_node.get("is_dead") == true

func _tick_damage_cooldowns(delta: float) -> void:
	for enemy_id in _damage_cooldowns.keys():
		var time_left := float(_damage_cooldowns[enemy_id]) - delta
		if time_left <= 0.0:
			_damage_cooldowns.erase(enemy_id)
		else:
			_damage_cooldowns[enemy_id] = time_left

func _damage_overlapping_enemies() -> void:
	for body in get_overlapping_bodies():
		if body == null or not is_instance_valid(body):
			continue
		if not body.is_in_group("enemy") or not body.has_method("take_damage"):
			continue

		var enemy_id := body.get_instance_id()
		if _damage_cooldowns.has(enemy_id):
			continue

		body.call("take_damage", damage)
		_damage_cooldowns[enemy_id] = damage_interval

extends CharacterBody2D

signal kill
signal request_pool_return(instance: Node)

const MAX_HEALTH := 80.0
const BOOM_SCENE := preload("res://Scenes/RobbieBoom.tscn")
const CASH_SCENE := preload("res://Scenes/Cash.tscn")

@export var ai_update_interval: float = 0.10

var health = MAX_HEALTH
var knockback_strength = 100.0
var knockback_duration = 0.1
var knockback_timer = 0.01  # Keeps track of the knockback time
var knockback_velocity = Vector2.ZERO  # Stores knockback velocity
var is_dying = false
var death_explosion_delay = 0.18

@onready var robbie: Node2D = %Tank
@onready var damage_numbers_origin: Node2D = $DamageNumberOrigin
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var queue_timer: Timer = $QueueTimer

var move_speed = 90.0  # Movement speed
var is_pursuing = false  # Whether the enemy is pursuing the player
var stop_distance = 200.0
var max_distance_from_player = 1200.0  # Maximum distance from player before queue_free
var active := true
var pooled := false
var _lifecycle_id := 0
var ai_timer := 0.0
var cached_target: Node2D = null
var cached_direction := Vector2.ZERO
var cached_target_distance_sq := INF

func _ready():
	_configure_ai_interval()
	reset_ai_state()
	%Tank.play_move()
	rotation = 0

func set_pooled(value: bool) -> void:
	pooled = value

func activate(spawn_position: Vector2, _data: Dictionary = {}) -> void:
	_lifecycle_id += 1
	active = true
	is_dying = false
	health = MAX_HEALTH
	knockback_timer = 0.0
	knockback_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	global_position = spawn_position
	rotation = 0
	if not is_in_group("enemy"):
		add_to_group("enemy")
	if collision_shape_2d:
		collision_shape_2d.disabled = false
		collision_shape_2d.set_deferred("disabled", false)
	if queue_timer:
		queue_timer.start()
	reset_ai_state(true)
	if not active:
		return
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_physics_process(true)
	%Tank.play_move()

func deactivate(return_to_pool: bool = true) -> void:
	if not active and return_to_pool:
		return

	_lifecycle_id += 1
	active = false
	is_dying = false
	health = MAX_HEALTH
	velocity = Vector2.ZERO
	knockback_timer = 0.0
	knockback_velocity = Vector2.ZERO
	reset_ai_state()
	visible = false
	remove_from_group("enemy")
	_stop_child_guns()
	set_physics_process(false)
	process_mode = Node.PROCESS_MODE_DISABLED
	if queue_timer:
		queue_timer.stop()
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)

	if pooled:
		if return_to_pool:
			request_pool_return.emit(self)
	elif return_to_pool:
		queue_free()

func _physics_process(delta):
	if not active or is_dying:
		return

	_update_ai_timer(delta)
	if not active or is_dying:
		return

	if knockback_timer > 0:
		velocity = knockback_velocity
		knockback_timer -= delta # decrease knockback time 
	else:
		pursue_player()
	move_and_slide()

func take_damage(damage):
	if not active or is_dying:
		return

	health -= damage + 15
	%Tank.play_hurt()
	DamageNumbers.display_number(20, damage_numbers_origin.global_position, true)
	
	var knockback_direction := _get_knockback_direction()
	if knockback_direction != Vector2.ZERO:
		knockback_velocity = knockback_direction * knockback_strength
		knockback_timer = knockback_duration
	
	if health <= 0.0:
		_die()

func _die():
	if is_dying:
		return
	is_dying = true
	emit_signal("kill")
	_stop_child_guns()
	var lifecycle_id := _lifecycle_id
	var death_position := global_position
	await get_tree().create_timer(death_explosion_delay).timeout
	if lifecycle_id != _lifecycle_id or not active:
		return

	_spawn_effect(BOOM_SCENE, death_position)
	_spawn_cash(death_position)
	deactivate()

func pursue_player():
	if cached_target_distance_sq > stop_distance * stop_distance:
		velocity = cached_direction * move_speed
	else:
		velocity = Vector2.ZERO

func check_distance_from_player():
	if cached_target_distance_sq > max_distance_from_player * max_distance_from_player:
		deactivate()

func reset_ai_state(refresh_now := false) -> void:
	cached_target = null
	cached_direction = Vector2.ZERO
	cached_target_distance_sq = INF
	ai_timer = randf_range(0.0, maxf(ai_update_interval, 0.01))
	if refresh_now:
		update_ai_decision()

func update_ai_decision() -> void:
	cached_target = get_best_target()
	cached_target_distance_sq = INF

	if not _is_valid_target(cached_target):
		cached_target = null
		cached_direction = Vector2.ZERO
		return

	var to_target := cached_target.global_position - global_position
	cached_target_distance_sq = to_target.length_squared()
	check_distance_from_player()
	if not active:
		return

	if cached_target_distance_sq > 0.001:
		cached_direction = to_target.normalized()
	else:
		cached_direction = Vector2.ZERO

func get_best_target() -> Node2D:
	var player_candidate = Global.player
	if player_candidate is Node2D and is_instance_valid(player_candidate):
		return player_candidate
	return null

func _update_ai_timer(delta: float) -> void:
	ai_timer -= delta
	if ai_timer > 0.0:
		return

	update_ai_decision()
	ai_timer = randf_range(ai_update_interval * 0.85, ai_update_interval * 1.15)

func _configure_ai_interval() -> void:
	ai_update_interval = maxf(0.02, ai_update_interval + randf_range(-0.02, 0.02))
	if OS.get_name() == "iOS" or OS.get_name() == "Android":
		ai_update_interval *= 1.25

func _is_valid_target(target: Node) -> bool:
	return target is Node2D and is_instance_valid(target)

func _get_knockback_direction() -> Vector2:
	var target := cached_target
	if not _is_valid_target(target):
		target = get_best_target()
	if _is_valid_target(target):
		return (global_position - target.global_position).normalized()
	return Vector2.ZERO

func _on_kill() -> void:
	GameManager._on_kill(1)

func _on_queue_timer_timeout() -> void:
	deactivate()

func _stop_child_guns() -> void:
	var basic_gun := get_node_or_null("%BasicGun")
	if basic_gun != null and basic_gun.has_method("stop_shooting"):
		basic_gun.call("stop_shooting")

func _spawn_effect(scene: PackedScene, spawn_position: Vector2) -> void:
	var pool_manager := _get_pool_manager()
	if pool_manager != null and pool_manager.has_method("spawn_effect"):
		pool_manager.call("spawn_effect", scene, spawn_position)
		return

	var effect := scene.instantiate() as Node2D
	if effect == null:
		return
	effect.global_position = spawn_position
	get_tree().current_scene.call_deferred("add_child", effect)

func _spawn_cash(spawn_position: Vector2) -> void:
	var pool_manager := _get_pool_manager()
	if pool_manager != null and pool_manager.has_method("spawn_cash"):
		pool_manager.call("spawn_cash", spawn_position, true)
		return

	var cash := CASH_SCENE.instantiate() as Node2D
	if cash == null:
		return
	if cash.has_method("randomize_power_up"):
		cash.call("randomize_power_up")
	cash.global_position = spawn_position
	get_tree().current_scene.call_deferred("add_child", cash)

func _get_pool_manager() -> Node:
	return get_tree().get_first_node_in_group("survival_pool_manager")

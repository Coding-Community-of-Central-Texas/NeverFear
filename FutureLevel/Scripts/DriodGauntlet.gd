extends CharacterBody2D

signal kill
signal request_pool_return(instance: Node)

const MAX_HEALTH := 15.0
const BOOM_SCENE := preload("res://Scenes/Boom.tscn")
const CASH_SCENE := preload("res://Scenes/Cash.tscn")
const MOVE_SPEED := 100.0

@export var ai_update_interval: float = 0.15
@export var max_spawn_lifetime: float = 45.0
@export var spawn_grace_time: float = 0.2

var health: float = MAX_HEALTH
var wave_health_scale: float = 1.0
var knockback_strength = 300.0
var knockback_duration = 0.3
var knockback_timer = 0.2  # Keeps track of the knockback time
var knockback_velocity = Vector2.ZERO  # Stores knockback velocity
var is_dying := false

@onready var driod: Node2D = %Driod
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var damage_numbers_origin: Node2D = $DamageNumbersOrigin
@onready var queue_timer: Timer = $QueueTimer

var max_distance_from_player = 1200.0
var active := true
var pooled := false
var ai_timer := 0.0
var cached_target: Node2D = null
var cached_direction := Vector2.ZERO
var cached_target_distance_sq := INF
var spawn_grace_active := false
var spawn_timer_id := 0
var spawn_position_anchor := Vector2.ZERO

func _ready():
	_configure_ai_interval()
	reset_ai_state()
	_start_lifetime_timer()
	start_spawn_timer()
	%Driod.play_walk()

func set_pooled(value: bool) -> void:
	pooled = value

func activate(spawn_position: Vector2, data: Dictionary = {}) -> void:
	active = true
	is_dying = false
	apply_wave_scaling(data)
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
	_start_lifetime_timer()
	reset_ai_state(true)
	if not active:
		return
	process_mode = Node.PROCESS_MODE_INHERIT
	%Driod.play_walk()
	start_spawn_timer()

func deactivate(return_to_pool: bool = true) -> void:
	if not active and return_to_pool:
		return

	active = false
	spawn_timer_id += 1
	spawn_grace_active = false
	is_dying = false
	wave_health_scale = 1.0
	health = MAX_HEALTH
	velocity = Vector2.ZERO
	knockback_timer = 0.0
	knockback_velocity = Vector2.ZERO
	reset_ai_state()
	visible = false
	remove_from_group("enemy")
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
	if not active or is_dying or spawn_grace_active:
		velocity = Vector2.ZERO
		return

	_update_ai_timer(delta)
	if not active or is_dying or spawn_grace_active:
		velocity = Vector2.ZERO
		return

	if knockback_timer > 0:
		velocity = knockback_velocity
		knockback_timer -= delta # decrease knockback time 
	else:
		velocity = cached_direction * MOVE_SPEED
	move_and_slide()


func apply_wave_scaling(data: Dictionary = {}) -> void:
	wave_health_scale = maxf(float(data.get("health_scale", 1.0)), 0.1)
	health = _get_scaled_max_health()

func _get_scaled_max_health() -> float:
	return MAX_HEALTH * wave_health_scale

func take_damage(damage: float) -> void:
	if not active or is_dying or spawn_grace_active:
		return

	health = maxf(health - damage, 0.0)
	DamageNumbers.display_number(5, damage_numbers_origin.global_position, true)
	if health <= 0.0:
		_die()
		return
	
	var knockback_direction := _get_knockback_direction()
	if knockback_direction != Vector2.ZERO:
		knockback_velocity = knockback_direction * knockback_strength
		knockback_timer = knockback_duration


func _die() -> void:
	if is_dying:
		return
	is_dying = true
	%Driod.play_die()
	emit_signal("kill")
	_spawn_effect(BOOM_SCENE, global_position)
	_spawn_cash(global_position)
	deactivate()

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
	ai_update_interval = maxf(0.02, ai_update_interval + randf_range(-0.03, 0.03))
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

func _start_lifetime_timer() -> void:
	if queue_timer == null:
		return
	if max_spawn_lifetime <= 0.0:
		queue_timer.stop()
		return
	queue_timer.start(max_spawn_lifetime)

func start_spawn_timer() -> void:
	spawn_timer_id += 1
	var timer_id := spawn_timer_id
	spawn_grace_active = true
	spawn_position_anchor = global_position
	visible = false
	velocity = Vector2.ZERO
	remove_from_group("enemy")
	if collision_shape_2d:
		collision_shape_2d.disabled = true
		collision_shape_2d.set_deferred("disabled", true)
	set_physics_process(false)

	if spawn_grace_time > 0.0:
		await get_tree().create_timer(spawn_grace_time).timeout

	if timer_id != spawn_timer_id or not active:
		return

	global_position = spawn_position_anchor
	velocity = Vector2.ZERO
	spawn_grace_active = false
	if not is_in_group("enemy"):
		add_to_group("enemy")
	if collision_shape_2d:
		collision_shape_2d.disabled = false
		collision_shape_2d.set_deferred("disabled", false)
	visible = true
	set_physics_process(true)

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

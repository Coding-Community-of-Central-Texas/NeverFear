extends CharacterBody2D

signal kill
signal request_pool_return(instance: Node)

const MAX_HEALTH := 20.0
const BOOM_SCENE := preload("res://Scenes/Boom.tscn")
const CASH_SCENE := preload("res://Scenes/Cash.tscn")

@export var ai_update_interval: float = 0.12
@export var max_spawn_lifetime: float = 45.0
@export var spawn_grace_time: float = 0.2

var health: float = MAX_HEALTH
var wave_health_scale: float = 1.0
var knockback_strength: float = 100.0
var knockback_duration: float = 0.1
var knockback_timer: float = 0.01
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var damage_numbers_origin: Node2D = $DamageNumbersOrigin
@onready var buff_byte: Node2D = $BuffByte
@onready var queue_timer: Timer = $QueueTimer

var max_distance_from_player: float = 1100.0
var attack_distance: float = 80.0
var can_attack: bool = true
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var active := true
var pooled := false
var ai_timer := 0.0
var cached_target: Node2D = null
var cached_direction := Vector2.ZERO
var cached_target_distance_sq := INF
var spawn_grace_active := false
var spawn_timer_id := 0
var spawn_position_anchor := Vector2.ZERO

func _ready() -> void:
	_configure_ai_interval()
	reset_ai_state()
	_start_lifetime_timer()
	start_spawn_timer()
	buff_byte.play_move()

func set_pooled(value: bool) -> void:
	pooled = value

func activate(spawn_position: Vector2, data: Dictionary = {}) -> void:
	active = true
	apply_wave_scaling(data)
	knockback_timer = 0.0
	knockback_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	can_attack = true
	attack_timer = 0.0
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
	buff_byte.play_move()
	start_spawn_timer()

func deactivate(return_to_pool: bool = true) -> void:
	if not active and return_to_pool:
		return

	active = false
	spawn_timer_id += 1
	spawn_grace_active = false
	wave_health_scale = 1.0
	health = MAX_HEALTH
	velocity = Vector2.ZERO
	knockback_timer = 0.0
	knockback_velocity = Vector2.ZERO
	can_attack = true
	attack_timer = 0.0
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

func _physics_process(delta: float) -> void:
	if not active or spawn_grace_active:
		velocity = Vector2.ZERO
		return

	_update_ai_timer(delta)
	if not active or spawn_grace_active:
		velocity = Vector2.ZERO
		return

	if knockback_timer > 0.0:
		velocity = knockback_velocity
		knockback_timer -= delta
	else:
		velocity = cached_direction * 60.0

	move_and_slide()
	_tick_attack_cooldown(delta)

func _tick_attack_cooldown(delta: float) -> void:
	if can_attack:
		return

	attack_timer -= delta
	if attack_timer <= 0.0:
		can_attack = true

func try_attack_player() -> void:
	if not active:
		return
	buff_byte.play_attack()

func apply_wave_scaling(data: Dictionary = {}) -> void:
	wave_health_scale = maxf(float(data.get("health_scale", 1.0)), 0.1)
	health = _get_scaled_max_health()

func _get_scaled_max_health() -> float:
	return MAX_HEALTH * wave_health_scale

func take_damage(damage: float) -> void:
	if not active or spawn_grace_active:
		return

	health -= damage
	%Byte.play_hurt()
	DamageNumbers.display_number(5, damage_numbers_origin.global_position, true)

	var knockback_direction := _get_knockback_direction()
	if knockback_direction != Vector2.ZERO:
		knockback_velocity = knockback_direction * knockback_strength
		knockback_timer = knockback_duration

	if health <= 0.0:
		_die()

func _die() -> void:
	emit_signal("kill")
	_spawn_effect(BOOM_SCENE, global_position)
	_spawn_cash(global_position)
	deactivate()

func check_distance_from_player() -> void:
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

	if can_attack and cached_target_distance_sq <= attack_distance * attack_distance:
		try_attack_player()
		can_attack = false
		attack_timer = attack_cooldown

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
	ai_update_interval = maxf(0.02, ai_update_interval + randf_range(-0.025, 0.025))
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

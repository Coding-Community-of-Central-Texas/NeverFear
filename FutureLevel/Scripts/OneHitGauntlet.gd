extends CharacterBody2D

signal kill

var health: float = 20.0
var knockback_strength: float = 300.0
var knockback_duration: float = 0.2
var knockback_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var damage_numbers_origin: Node2D = $DamageNumbersOrigin
@onready var buff_byte: Node2D = $BuffByte

var max_distance_from_player: float = 1100.0
var attack_distance: float = 80.0
var can_attack: bool = true
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0

func _ready() -> void:
	buff_byte.play_move()

func _physics_process(delta: float) -> void:
	if not Global.player:
		return

	if knockback_timer > 0.0:
		velocity = knockback_velocity
		knockback_timer -= delta
	else:
		var direction: Vector2 = global_position.direction_to(Global.player.global_position)
		velocity = direction * 60.0

	move_and_slide()
	check_distance_from_player()
	_check_attack(delta)

func _check_attack(delta: float) -> void:
	if not Global.player:
		return

	var distance_to_player: float = global_position.distance_to(Global.player.global_position)

	if can_attack and distance_to_player <= attack_distance:
		try_attack_player()
		can_attack = false
		attack_timer = attack_cooldown
	elif not can_attack:
		attack_timer -= delta
		if attack_timer <= 0.0:
			can_attack = true

func try_attack_player() -> void:
	buff_byte.play_attack()

func take_damage(damage: float) -> void:
	health -= damage
	%Byte.play_hurt()
	DamageNumbers.display_number(5, damage_numbers_origin.global_position, true)

	if Global.player:
		var knockback_direction: Vector2 = (global_position - Global.player.global_position).normalized()
		knockback_velocity = knockback_direction * knockback_strength
		knockback_timer = knockback_duration

	if health <= 0.0:
		_die()

func _die() -> void:
	emit_signal("kill")

	const BOOM = preload("res://Scenes/Boom.tscn")
	var new_boom = BOOM.instantiate()
	new_boom.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", new_boom)

	const CASH = preload("res://Scenes/Cash.tscn")
	var new_cash = CASH.instantiate()
	new_cash.randomize_power_up()
	new_cash.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", new_cash)

	queue_free()

func check_distance_from_player() -> void:
	if Global.player:
		var distance_to_player: float = global_position.distance_to(Global.player.global_position)
		if distance_to_player > max_distance_from_player:
			queue_free()

func _on_kill() -> void:
	GameManager._on_kill(1)

func _on_queue_timer_timeout() -> void:
	queue_free()

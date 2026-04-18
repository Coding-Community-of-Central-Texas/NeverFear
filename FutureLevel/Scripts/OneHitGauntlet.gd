extends CharacterBody2D

signal kill

var health = 20.0
var knockback_strength = 300.0
var knockback_duration = 0.2
var knockback_timer = 0.25  # Keeps track of the knockback time
var knockback_velocity = Vector2.ZERO  # Stores knockback velocity


@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var damage_numbers_origin: Node2D = $DamageNumbersOrigin
@onready var buff_byte: Node2D = $BuffByte

var max_distance_from_player = 1100.0

var attack_distance = 80.0  # Distance to trigger attack
var can_attack = true
var attack_cooldown = 1.0  # Cooldown in seconds
var attack_timer = 0.0

func _ready():
	buff_byte.play_move()

func _physics_process(delta):
	if knockback_timer > 0:
		velocity = knockback_velocity
		knockback_timer -= delta # decrease knockback time 
	else:
		var direction = (Global.player.global_position - global_position).normalized()
		global_position.direction_to(Global.player.global_position)
		velocity = direction * 60.0
		move_and_slide()
	check_distance_from_player()
	_check_attack(delta)
	move_and_slide()

func _check_attack(delta):
	if not Global.player:
		return
	var distance_to_player = global_position.distance_to(Global.player.global_position)
	if can_attack and distance_to_player <= attack_distance:
		try_attack_player()
		can_attack = false
		attack_timer = attack_cooldown
	elif not can_attack:
		attack_timer -= delta
		if attack_timer <= 0.0:
			can_attack = true

func try_attack_player():
	buff_byte.play_attack()

func take_damage(damage):
	health -= damage
	%Byte.play_hurt()
	DamageNumbers.display_number(5, damage_numbers_origin.global_position, true)
	
	var knockback_direction = (global_position - Global.player.global_position).normalized()
	knockback_velocity = knockback_direction * knockback_strength
	
	knockback_timer = knockback_duration
	
	if health == 0.0:
		_die()


func _die():
	emit_signal("kill")
	const BOOM = preload("res://Scenes/Boom.tscn")
	var new_Boom = BOOM.instantiate()
	new_Boom.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", new_Boom)
	
	const CASH = preload("res://Scenes/Cash.tscn")
	var new_Cash = CASH.instantiate()
	new_Cash.randomize_power_up()
	new_Cash.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", new_Cash)
	queue_free()

func check_distance_from_player():
	if Global.player:
		var distance_to_player = global_position.distance_to(Global.player.global_position)
		if distance_to_player > max_distance_from_player:
			queue_free()

func _on_kill() -> void:
	GameManager._on_kill(1)


func _on_queue_timer_timeout() -> void:
	queue_free()

extends CharacterBody2D

signal kill

var health = 15.0
var knockback_strength = 300.0
var knockback_duration = 0.3
var knockback_timer = 0.2  # Keeps track of the knockback time
var knockback_velocity = Vector2.ZERO  # Stores knockback velocity

@onready var driod: Node2D = %Driod
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var damage_numbers_origin: Node2D = $DamageNumbersOrigin

var max_distance_from_player = 1200.0

func _ready():
	%Driod.play_walk()

func _physics_process(delta):
	if knockback_timer > 0:
		velocity = knockback_velocity
		knockback_timer -= delta # decrease knockback time 
	else:
		var direction = (Global.player.global_position - global_position).normalized()
		global_position.direction_to(Global.player.global_position)
		velocity = direction * 50.0
		move_and_slide()
	check_distance_from_player()
	move_and_slide()


func take_damage():
	health -= 5.0
	%Driod.play_die()
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

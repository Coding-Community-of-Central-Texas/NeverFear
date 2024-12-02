extends CharacterBody2D


var health = 70.0
var knockback_strength = 500.0
var knockback_duration = 0.7
var knockback_timer = 0.0  # Keeps track of the knockback time
var knockback_velocity = Vector2.ZERO  # Stores knockback velocity

@onready var tank: Node2D = %Tank
@onready var ground_ray_right: RayCast2D = $GroundRayRight
@onready var ground_ray_left: RayCast2D = $GroundRayLeft
@onready var left_wall_ray: RayCast2D = $LeftWallRay
@onready var right_wall_ray: RayCast2D = $RightWallRay



var move_speed = 100.0  # Movement speed
var max_distance = 150.0  # The max distance to move before reversing direction
var direction = 1  # 1 for right, -1 for left


var platform_edge_offset = 20.0  # Distance from the edge of the platform to reverse direction
var starting_position = Vector2.ZERO


func _ready():
	%Tank.play_move()
	starting_position = global_position
	if velocity.x > 0:
		%Tank.flip_h = false
	elif velocity.x < 0: 
		%Tank.flip_h = true

func _physics_process(_delta):
	if not is_on_floor():
		velocity += get_gravity() * _delta

	if knockback_timer > 0:
		velocity = knockback_velocity
		knockback_timer -= _delta # decrease knockback time 
	else:
		back_and_forth_movement()
	move_and_slide()


func take_damage():
	health -= 10.0
	%Tank.play_hurt()
	
	var knockback_direction = (global_position - Global.player.global_position).normalized()
	knockback_velocity = knockback_direction * knockback_strength
	knockback_timer = knockback_duration
	
	if health == 0.0:
		_die()

func _die():
	
	const BOOM = preload("res://Scenes/RobbieBoom.tscn")
	var new_Boom = BOOM.instantiate()
	new_Boom.global_position = global_position
	get_parent().add_child(new_Boom)
	
	const CASH = preload("res://Scenes/Cash.tscn")
	var new_Cash = CASH.instantiate()
	new_Cash.randomize_power_up()
	new_Cash.global_position = global_position 
	get_tree().current_scene.call_deferred("add_child", new_Cash)
	queue_free()

func back_and_forth_movement():
	velocity.x = direction * move_speed

	if is_near_platform_edge():
		direction = -direction  # Reverse direction to avoid falling off the platform
	elif is_near_wall():
		direction = -direction

func handle_flip():
	if velocity.x > 0:
		%Tank.flip_h = false
	elif velocity.x < 0: 
		%Tank.flip_h = true

func is_near_wall() -> bool:
	if direction == 1:
		return right_wall_ray.is_colliding()
	elif direction == -1:
		return left_wall_ray.is_colliding()
	return false 

func is_near_platform_edge() -> bool:
	if direction == 1:
		return !ground_ray_right.is_colliding()
	elif direction == -1: 
		return !ground_ray_left.is_colliding()
	return false

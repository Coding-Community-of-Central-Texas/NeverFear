extends CharacterBody2D

signal kill

var health = 60.0
var knockback_strength = 0.5
var knockback_duration = 0.1
var knockback_timer = 0.0  # Keeps track of the knockback time
var knockback_velocity = Vector2.ZERO  # Stores knockback velocity

@onready var robbie: Node2D = %Tank

var move_speed = 200.0  # Movement speed
var is_pursuing = false  # Whether the enemy is pursuing the player
var stop_distance = 320.0

func _ready():
	%Tank.play_move()
	rotation = 0

func _physics_process(delta):

	if knockback_timer > 0:
		velocity = knockback_velocity
		knockback_timer -= delta # decrease knockback time 
	else:
		pursue_player()
	move_and_slide()


func take_damage():
	health -= 20.0
	%Tank.play_hurt()
	
	var knockback_direction = (global_position - Global.player.global_position).normalized()
	knockback_velocity = knockback_direction * knockback_strength
	knockback_timer = knockback_duration
	
	if health == 0.0:
		emit_signal("kill")
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


func pursue_player():
	if Global.player:
		var distance_to_player = global_position.distance_to(Global.player.global_position)  # Get the distance
		var direction_to_player = (Global.player.global_position - global_position).normalized()
		
		# If the enemy is farther than the stop distance, pursue the player
		if distance_to_player > stop_distance:
			velocity = direction_to_player * move_speed
		else:
			velocity = Vector2.ZERO  # Stop moving if within stop distance


func _on_kill() -> void:
	GameManager._on_kill()
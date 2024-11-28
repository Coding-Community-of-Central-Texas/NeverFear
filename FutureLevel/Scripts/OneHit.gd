extends CharacterBody2D

var health = 10.0
var knockback_strength = 320.0
var knockback_duration = 0.1
var knockback_timer = 0.0  # Keeps track of the knockback time
var knockback_velocity = Vector2.ZERO  # Stores knockback velocity

@onready var byte: Node2D = %Byte
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var player: CharacterBody2D = $"../../Hero"
@onready var timer: Timer = $Timer


func _ready():
	%Byte.play_walk()
	timer.connect("timeout", Callable (self, "_on_knockback_timeout"))

func _physics_process(delta):
	if knockback_timer > 0:
		velocity = knockback_velocity
		knockback_timer -= delta # decrease knockback time 
	else:
		var direction = (player.global_position - global_position).normalized()
		global_position.direction_to(player.global_position)
		velocity = direction * 200.0
		move_and_slide()
	
	move_and_slide()


func take_damage():
	health -= 5.0
	%Byte.play_hurt()
	
	var knockback_direction = (global_position - player.global_position).normalized()
	knockback_velocity = knockback_direction * knockback_strength
	
	knockback_timer = knockback_duration
	
	if health == 0.0:
		queue_free()
		print("Kill confirmed")
		_die()
		await timer.timeout




func _die():
	
	const BOOM = preload("res://Scenes/Boom.tscn")
	var new_Boom = BOOM.instantiate()
	new_Boom.global_position = global_position
	get_parent().add_child(new_Boom)
	
	const CASH = preload("res://Scenes/Cash.tscn")
	var new_Cash = CASH.instantiate()
	new_Cash.global_position = global_position
	get_parent().add_child(new_Cash)
	call_deferred("queue_free")
	

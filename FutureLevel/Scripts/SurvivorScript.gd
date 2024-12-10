
extends CharacterBody2D

# Player properties
var health: float = 100.0
const MAX_HEALTH = 100
var direction: Vector2 = Vector2.ZERO
const VELOCITY = 1000
@export var SPEED: float = 500.0
@export var acceleration: float = 800.0
@export var deceleration: float = 1000.0
@onready var spawn_circle: Path2D = $SpawnCircle


# Animation setup
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = %HealthBar
@onready var timer_2: Timer = $Timer2
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@export var rate_of_fire: float = 0.15

func _ready() -> void:
	# Initialize the player's properties
	Global.player = self

func take_damage():
	health -= 15.0
	health_bar.value = health
	if health <= 0.0:
		_die()

func _die():
	animated_sprite_2d.play("death")
	timer_2.start()
	if not audio_stream_player.is_playing():
		audio_stream_player.play()


func _physics_process(delta: float) -> void:
	handle_player_animation()
	var target_velocity = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		target_velocity.y -= 1
	if Input.is_action_pressed("move_down"):
		target_velocity.y += 1
	if Input.is_action_pressed("move_left"):
		target_velocity.x -= 1
	if Input.is_action_pressed("move_right"):
		target_velocity.x += 1

	if target_velocity.length() > 0:
		target_velocity = target_velocity.normalized() * SPEED

	# Smoothly accelerate or decelerate
	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	move_and_slide()
	flip_sprite()
	
	const DAMAGE_RATE = 10.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	health_bar.value = health
	
	if overlapping_mobs.size() > 0:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		health_bar.value = health
	if health == 0.0:
		take_damage()
		



# Function to handle the player animation based on movement
func handle_player_animation() -> void:
	# If the player is moving, play the "run" animation
	if velocity.length() > 0:
		if !animation_player.is_playing() or animation_player.current_animation != "walk":
			animation_player.play("walk")
	# If the player is not moving, play the "idle" animation
	else:
		if !animation_player.is_playing() or animation_player.current_animation != "idle":
			animation_player.play("idle")

#Function to flip the sprite depending on the direction
func flip_sprite() -> void:
	if velocity.x < 0:
		animated_sprite_2d.flip_h = true
	elif velocity.x > 0:
		animated_sprite_2d.flip_h = false
	spawn_circle.rotation = 0  # Prevents rotation effects, if any


const GAME_OVER = preload("res://Scenes/GameOver.tscn")

func _on_timer_2_timeout() -> void:
	var gameover = GAME_OVER.instantiate()
	add_child(gameover)

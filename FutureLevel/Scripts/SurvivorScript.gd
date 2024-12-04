
extends CharacterBody2D

# Player properties
var health: float = 100.0
const MAX_HEALTH: float = 100.0
var direction: Vector2 = Vector2.ZERO
const VELOCITY = 1000
@export var SPEED: float = 400.0
@export var acceleration: float = 800.0
@export var deceleration: float = 600.0


# Animation setup
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = %HealthBar
@onready var timer_2: Timer = $Timer2
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@export var rate_of_fire: float = 0.15
var is_dead = false

func _ready() -> void:
	# Initialize the player's properties
	health = MAX_HEALTH
	Global.player = self

func take_damage():
	if is_dead:
		return
	health -= 15.0
	health_bar.health = health
	%AnimationPlayer.play("hurt")
	if health <= 0.0:
		_die()
func _die():
	if is_dead:
		return
	is_dead = true 
	Global.lives -= 1
	if Global.lives <= 0:
		_on_game_over()

	else:
		timer_2.start()
		animated_sprite_2d.play("death")
		Engine.time_scale = 0.6
		if not audio_stream_player.is_playing():
			audio_stream_player.play()

func _on_game_over():
	Global.reset_game_state()
	GameManager.toggle_pause()

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
		_die()
		



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
		# Flip the sprite when moving left (negative X velocity)
		self.scale.x = -1
	elif velocity.x > 0:
		# Unflip the sprite when moving right (positive X velocity)
		self.scale.x = 1



func _on_timer_2_timeout() -> void:
	get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")

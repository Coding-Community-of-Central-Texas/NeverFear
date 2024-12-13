
extends CharacterBody2D

# Player properties
var health: float = 100.0
const MAX_HEALTH = 100
var direction: Vector2 = Vector2.ZERO
const VELOCITY = 1000
@export var SPEED: float = 600.0
@export var acceleration: float = 2000.0
@export var deceleration: float = 5000.0
@onready var shadow: Sprite2D = $AnimatedSprite2D/Shadow



# Animation setup
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = %HealthBar
@onready var timer_2: Timer = $Timer2
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@export var rate_of_fire: float = 0.15

var is_dead: bool = false

func _ready() -> void:
	# Initialize the player's properties
	Global.player = self

func take_damage():
	if is_dead:
		return  # Ignore damage if the player is already dead
	health -= 4
	health_bar.value = health
	if health <= 0:
		_die()

func _die():
	if is_dead:
		return  # Ensure _die() only runs once
	is_dead = true
	animated_sprite_2d.play("death")
	timer_2.start()
	audio_stream_player.play()


func _physics_process(delta: float) -> void:
	handle_player_animation()
	var target_velocity = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		target_velocity.y -= 5
	if Input.is_action_pressed("move_down"):
		target_velocity.y += 5
	if Input.is_action_pressed("move_left"):
		target_velocity.x -= 10
	if Input.is_action_pressed("move_right"):
		target_velocity.x += 10

	if target_velocity.length() > 0:
		target_velocity = target_velocity.normalized() * SPEED

	# Smoothly accelerate or decelerate
	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	move_and_slide()
	flip_sprite()
	
	const DAMAGE_RATE = 5.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	health_bar.value = health
	
	if overlapping_mobs.size() > 0:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		health_bar.value = health
	if health <= 0:
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
	if velocity.x < -3:
		animated_sprite_2d.flip_h = true
		shadow.position.x = 5; shadow.position.y = 34;
	elif velocity.x > 3:
		animated_sprite_2d.flip_h = false
		shadow.position.x = -9.5; shadow.position.y = 34;





func _on_timer_2_timeout() -> void:
	_game_over()

func _game_over():
	const GAMEOVER = preload("res://Scenes/GameOver.tscn")
	var new_gameover = GAMEOVER.instantiate()
	add_child(new_gameover)


func _on_spawn_timer_timeout() -> void:
	const SPAWN = preload("res://Scenes/SpawnCircle.tscn")
	const BIGSPAWN = preload("res://Scenes/BigSpawnCircle.tscn")
	var new_big = BIGSPAWN.instantiate()
	var new_spawn = SPAWN.instantiate()
	get_tree().current_scene.add_child(new_big)
	get_tree().current_scene.add_child(new_spawn)

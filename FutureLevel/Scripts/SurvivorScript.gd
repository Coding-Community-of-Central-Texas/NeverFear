
extends CharacterBody2D

# Player properties
var health: float = 100.0
const MAX_HEALTH: float = 100.0
var SPEED: float = 600.0
var direction: Vector2 = Vector2.ZERO
const VELOCITY = 1000

# Animation setup
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
	get_tree().change_scene_to_file.call_deferred("res://Scenes/GameOver.tscn")

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_player_animation()
	move_and_slide()

	const DAMAGE_RATE = 10.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	health_bar.value = health
	
	if overlapping_mobs.size() > 0:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		health_bar.value = health
	if health == 0.0:
		_die()
		

# Handle movement based on joystick input
func handle_movement(delta: float) -> void:
	velocity = direction * SPEED

# Handle animations based on movement direction
func handle_player_animation() -> void:
	if direction == Vector2.ZERO:
		animated_sprite_2d.play("idle")
	else:
		if abs(direction.x) > abs(direction.y):  # Horizontal movement
			if direction.x > 0:
				animated_sprite_2d.play("run")
			else:
				animated_sprite_2d.play("run")
		else:  # Vertical movement
			
			if direction.y > 0:
				animated_sprite_2d.play("run")
			else:
				animated_sprite_2d.play("run")


func _on_joystick_joystick_input(strength, dir, delta) -> void:
	direction = dir * strength
	



func _on_joystick_joystick_released() -> void:
	direction = Vector2.ZERO

@onready var timer: Timer = $Timer


func _on_timer_timeout() -> void:
	spawn_wave()
	spawn_wave()
	spawn_wave()


func spawn_wave():
	const DROID  = preload("res://Scenes/DriodLegacy.tscn")
	const BYTE = preload("res://Scenes/OneHit.tscn")
	var new_byte = BYTE.instantiate()
	var new_droid = DROID.instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_droid.position = %PathFollow2D.position
	
	%PathFollow2D.progress_ratio += 0.1  # Adjust this value for desired spacing
	if %PathFollow2D.progress_ratio > 1.0:
		%PathFollow2D.progress_ratio -= 1.0  # Wrap around if it exceeds 1.0
		new_byte.position = %PathFollow2D.position
	new_byte.position = %PathFollow2D.position
	add_child(new_byte) 
	add_child(new_droid)

func _on_timer_2_timeout() -> void:
	get_tree().change_scene_to_file("res://Scenes/GameOver.tscn")

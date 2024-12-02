extends CharacterBody2D


var health = 100.0
const MAX_HEALTH = 100.0
var SPEED = 400.0
const JUMP_VELOCITY = -550.0
const DOUBLE_JUMP_VELOCITY = -666.0
const GRAVITY = 2000.0  # Custom gravity value
const COYOTE_TIME = 0.2  # Time to allow jumping after falling
const MAX_FALL_SPEED = 1000.0  # Limit the maximum fall speed
var direction : Vector2 = Vector2(0,0)


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var audio_stream_player_2d_2: AudioStreamPlayer2D = $AudioStreamPlayer2D2
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var timer: Timer = $Timer
@onready var gun: Area2D = $Gun
@onready var health_bar: ProgressBar = $HealthBar
@export var rate_of_fire: float = 0.15


var can_double_jump = false
var coyote_time_remaining = 0.0  # Keeps track of the coyote time
var is_double_jumping = false
var is_dead = false

func _ready() -> void:
	Global.player = self  # Assign the player reference
	health_bar.init_health(health)
	if Global.lives < 3:
		position = Global.checkpoint_position
	else: 
		position = Vector2(353.993, -306.008)
	

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
		timer.start()
		animated_sprite_2d.play("death")
		Engine.time_scale = 0.6
		if not audio_stream_player_2d_2.is_playing():
			audio_stream_player_2d_2.play()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	apply_gravity(delta)
	handle_jumping(delta)
	handle_movement(delta)
	handle_animation()
	
	if direction:
		velocity.x = direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
	
	const DAMAGE_RATE = 25.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	health_bar.value = health
	
	if overlapping_mobs.size() > 0:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		health_bar.value = health
		if health <= 0.0:
			take_damage()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
	else:
		coyote_time_remaining = COYOTE_TIME  # Reset coyote time
		can_double_jump = true
		is_double_jumping = false
		velocity.y = 0

func handle_jumping(delta: float) -> void:
	if !is_on_floor():
		coyote_time_remaining -= delta
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_time_remaining > 0.0:
			velocity.y = JUMP_VELOCITY
			can_double_jump = true  # Reset double jump
		elif can_double_jump:
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false
			is_double_jumping = true
			animated_sprite_2d.play("doublejump")
			audio_stream_player_2d.play()

	if Input.is_action_just_released("jump") and velocity.y <0:
		velocity.y *= 0.5

func handle_movement(_delta: float) -> void:
	if direction.x != 0:  # Use joystick's input direction
		velocity.x = direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func handle_animation() -> void:
	if health <= 0:
		if not animated_sprite_2d.is_playing() or animated_sprite_2d.animation != "death":
			animated_sprite_2d.play("death")
		return

	if animated_sprite_2d.animation == "hurt" and animated_sprite_2d.is_playing():
		return

	if is_double_jumping:
		return
	if velocity.x > 0:
		animated_sprite_2d.flip_h = false
	elif velocity.x < 0: 
		animated_sprite_2d.flip_h = true
	
	if velocity.y < 0:
		animated_sprite_2d.play("gunjump")
		
	elif is_on_floor():
		if abs(velocity.x) > 0:
			animated_sprite_2d.play("gunrun")
		else:
			animated_sprite_2d.play("gunidle")

func _respawn():
	# Reset the player's position, health, and state
	health = MAX_HEALTH
	health_bar.value = health
	is_dead = false
	Engine.time_scale = 1.0
	position = Global.checkpoint_position


func _on_timer_timeout() -> void:
	if Global.lives <= 0:
		_on_game_over()
	else:
		_respawn()


func _on_game_over():
	get_tree().change_scene_to_file.call_deferred("res://Scenes/GameOver.tscn")


func _on_joystick_joystick_input(_strength, dir, _delta) -> void:
		direction = dir

extends CharacterBody2D
signal input

# Player attributes
var health = 100.0
const MAX_HEALTH = 100.0
var SPEED = 600.0
const JUMP_VELOCITY = -550.0
const DOUBLE_JUMP_VELOCITY = -666.0
const COYOTE_TIME = 0.2  # Time to allow jumping after falling
const GRAVITY = 200.0
const MAX_FALL_SPEED = 1000.0
@export var acceleration: int = 100
@export var deceleration: int = 150  # Increased for reduced sliding
@export var air_control: float = 0.6  # Improved midair responsiveness

# New mechanics
const JUMP_BUFFER_TIME = 0.2  # Buffer time for jump input
var jump_buffer_timer = 0.0  # Timer for jump buffer

var can_double_jump = false
var coyote_time_remaining = 0.0
var is_double_jumping = false
var is_dead = false
var direction : Vector2 = Vector2.ZERO

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	Global.player = self  # Assign the player reference
	health_bar.init_health(health)
	if Global.lives < 3:
		position = Global.checkpoint_position
	else: 
		position = Vector2(353.993, -306.008)
	

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	apply_gravity(delta)
	handle_jumping(delta)
	handle_movement(delta)
	handle_animation(delta)

	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
	else:
		coyote_time_remaining = COYOTE_TIME
		can_double_jump = true
		is_double_jumping = false
		velocity.y = 0  # Reset vertical velocity

func handle_jumping(delta: float) -> void:
	if not is_on_floor():
		coyote_time_remaining -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME  # Store the jump input

	if jump_buffer_timer > 0.0:
		if is_on_floor() or coyote_time_remaining > 0.0:
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0.0  # Reset buffer timer
			can_double_jump = true
		elif can_double_jump:
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false
			is_double_jumping = true
			animated_sprite_2d.play("doublejump")

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5  # Short hop for released jump

func handle_movement(delta: float) -> void:
	var input_direction = Vector2.ZERO

	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1

	input_direction = input_direction.normalized()
	var target_velocity = input_direction * SPEED

	if is_on_floor():
		velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
		if abs(velocity.x) < 5.0:
			velocity.x = 0  # Stop small sliding
	else:
		velocity.x = lerp(velocity.x, target_velocity.x, acceleration * air_control * delta)

	move_and_slide()

func handle_animation(delta: float) -> void:
	if is_dead:
		if not animated_sprite_2d.is_playing() or animated_sprite_2d.animation != "death":
			animated_sprite_2d.play("death")
		return

	if is_double_jumping:
		return

	animated_sprite_2d.flip_h = velocity.x < 0

	if velocity.y < 0:
		animated_sprite_2d.play("gunjump")
	elif is_on_floor():
		if abs(velocity.x) > 0:
			animated_sprite_2d.play("gunrun")
		else:
			animated_sprite_2d.play("gunidle")

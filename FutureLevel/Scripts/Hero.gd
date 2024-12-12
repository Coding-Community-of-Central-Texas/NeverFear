extends CharacterBody2D 

var health = 100.0
const MAX_HEALTH = 100.0
var SPEED = 600.0
const JUMP_VELOCITY = -1000.0
const DOUBLE_JUMP_VELOCITY = -1200.0
const GRAVITY = 4000.0  # Custom gravity value
const COYOTE_TIME = 0.2  # Time to allow jumping after falling
const MAX_FALL_SPEED = 3000.0  # Limit the maximum fall speed
var direction : Vector2 = Vector2.ZERO
@export var acceleration: float = 3000.0
@export var deceleration: float = 5000.0


@onready var audio_stream_player_2d_2: AudioStreamPlayer2D = $AudioStreamPlayer2D2
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
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
	health -= 10.0
	self.modulate = Color(1, 0, 0)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	self.modulate = Color(1, 1, 1)  # Reset to normal
	health_bar.health = health
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
	handle_jumping(delta)
	handle_movement(delta)
	handle_animation()
	
	#if is_on_floor():
		#var friction = 5
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		# Limit fall speed
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
	else:
		coyote_time_remaining = COYOTE_TIME  # Reset coyote time
		can_double_jump = true
		is_double_jumping = false
	
	move_and_slide()
	
	const DAMAGE_RATE = 20.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	health_bar.health = health
	
	if overlapping_mobs.size() > 0:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		health_bar.value = health
		if health <= 0.0:
			take_damage()



func handle_jumping(delta: float) -> void:
	if !is_on_floor():
		coyote_time_remaining -= delta
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_time_remaining > 0.0:
			velocity.y = JUMP_VELOCITY
			can_double_jump = true  # Reset double jump
			animated_sprite_2d.play("gunjump")
			audio_stream_player_2d.play()
		elif can_double_jump:
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false
			is_double_jumping = true
			animated_sprite_2d.play("doublejump")
			audio_stream_player_2d.play()

	if Input.is_action_just_released("jump") and velocity.y <0:
		velocity.y *= 0.5

func handle_movement(delta: float) -> void:
	var target_velocity_x = 0.0
	
	if Input.is_action_pressed("move_left"):
		target_velocity_x -= SPEED
	if Input.is_action_pressed("move_right"):
		target_velocity_x += SPEED

	# Smoothly adjust horizontal velocity
	if velocity.x < target_velocity_x:
		velocity.x += acceleration * delta
		velocity.x = min(velocity.x, target_velocity_x)  # Clamp to avoid overshooting
	elif velocity.x > target_velocity_x:
		velocity.x -= deceleration * delta
		velocity.x = max(velocity.x, target_velocity_x)  # Clamp to avoid overshooting

func handle_animation() -> void:
	if health <= 0:
		animated_sprite_2d.play("death")
		return
	
	if is_double_jumping:
		return
	if velocity.x > 0:
		animated_sprite_2d.flip_h = false
	elif velocity.x < 0: 
		animated_sprite_2d.flip_h = true
	
		
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left"):
		animated_sprite_2d.play("gunrun")
		if not is_on_floor():
			animated_sprite_2d.play("gunjump")
	else: 
		if is_on_floor() and not Input.is_action_pressed("jump") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
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
	const GAMEOVER = preload("res://Scenes/GameOver.tscn") 
	var new_gameover = GAMEOVER.instantiate()
	add_child(new_gameover)

func _on_pick_up_gun_picked_up() -> void:
	%Gun2.set_collision_mask_value(3, true)
	%Gun2.visible = true

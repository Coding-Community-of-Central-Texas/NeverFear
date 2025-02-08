extends CharacterBody2D 

var health = 100.0
const MAX_HEALTH = 100.0
@export var SPEED = 600.0
var previous_speed: float = SPEED
const JUMP_VELOCITY = -1100.0
const DOUBLE_JUMP_VELOCITY = -1300.0
const GRAVITY = 4000.0  # Custom gravity value
const COYOTE_TIME = 0.2  # Time to allow jumping after falling
const MAX_FALL_SPEED = 3500.0  # Limit the maximum fall speed
var direction : Vector2 = Vector2.ZERO
@export var acceleration: float = 4000.0
@export var deceleration: float = 7000.0

@onready var audio_stream_player_2d_2: AudioStreamPlayer2D = $AudioStreamPlayer2D2
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var timer: Timer = $Timer
@onready var gun: Area2D = $Gun
@onready var health_bar: ProgressBar = $HealthBar
@export var rate_of_fire: float = 0.15
@onready var jump_effect: CPUParticles2D = %JumpEffect
@onready var walkn_jump_r: Marker2D = $AnimatedSprite2D/WalknJumpR
@onready var walkn_jump_l: Marker2D = $AnimatedSprite2D/WalknJumpL
@onready var super_sayain: AnimatedSprite2D = $AnimatedSprite2D/SuperSayain
@onready var jump_effect_2: CPUParticles2D = %JumpEffect2

var can_double_jump = false
var coyote_time_remaining = 0.0  # Keeps track of the coyote time
var is_double_jumping = false
var is_dead = false
var jump_effect_visible = false 
var is_walking: bool = false

func _ready() -> void:
	Global.player = self  # Assign the player reference
	health_bar.init_health(health)
	if Global.lives < 3:
		position = Global.checkpoint_position
	else: 
		position = Vector2(353.993, -306.008)

func take_damage(amount: int):
	if is_dead:
		return
	health -= amount
	self.modulate = Color(80, 0, 0)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	
	# Apply knockback
	var knockback_force = Vector2(-180, -180)  
	velocity += knockback_force
	
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
	
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		# Limit fall speed
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
	else:
		coyote_time_remaining = COYOTE_TIME  # Reset coyote time
		can_double_jump = true
		is_double_jumping = false
	
	
	move_and_slide()
	if SPEED > previous_speed:
		_on_speed_increase()
	# Update the previous speed for the next frame
	previous_speed = SPEED
	
	const DAMAGE_RATE = 30.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	health_bar.health = health
	
	if overlapping_mobs.size() > 0:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		health_bar.value = health
		if health <= 0.0:
			take_damage(10)

func _on_speed_increase() -> void:
	# Make the particle node visible and emit particles
	super_sayain.visible = true 
	await get_tree().create_timer(3.0).timeout
	super_sayain.visible = false 

func handle_jumping(delta: float) -> void:
	if !is_on_floor():
		coyote_time_remaining -= delta
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_time_remaining > 0.0:
			velocity.y = JUMP_VELOCITY
			can_double_jump = true  # Reset double jump
			animated_sprite_2d.play("gunjump")
			_trigger_jump_effect()
			audio_stream_player_2d.play()
		elif can_double_jump:
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false
			is_double_jumping = true
			animated_sprite_2d.play("doublejump")
			_trigger_doublejump_effect()
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
		

func _trigger_jump_effect() -> void:
	# Make the particle effect visible and emit
	%JumpEffect.visible = true
	%JumpEffect.emitting = true
	%JumpEffect2.emitting = true
	
func _trigger_doublejump_effect() -> void:
	# Make the particle effect visible and emit
	%JumpEffect2.emitting = true 

func handle_animation() -> void:
	if health <= 0:
		animated_sprite_2d.play("death")
		return
	
	if is_double_jumping:
		return
	if velocity.x > 0:
		%AnimationPlayer.play("rightface")
	elif velocity.x < 0: 
		%AnimationPlayer.play("leftface")
		
		
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left"):
		if not animated_sprite_2d.is_playing():
			animated_sprite_2d.play("gunrun")
	else: 
		if is_on_floor() and not Input.is_action_pressed("jump") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
			if not animated_sprite_2d.is_playing():
				animated_sprite_2d.play("gunidle")

func _respawn():
	# Reset the player's position, health, and state
	health = MAX_HEALTH
	health_bar.value = health
	is_dead = false
	Engine.time_scale = 1.0
	if Global.returning_from_game:
		position = Global.hub_world_position
		Global.returning_from_game = false
	else:
		position = Global.checkpoint_position

func _on_timer_timeout() -> void:
	if Global.lives <= 0:
		_on_game_over()
	else:
		_respawn()

func _on_game_over():
	const GAMEOVER = preload("res://Scenes/GameOver.tscn") 
	var new_gameover = GAMEOVER.instantiate()
	get_tree().current_scene.add_child(new_gameover)

func _on_pick_up_gun_picked_up() -> void:
	%Gun2.set_collision_mask_value(3, true)
	%Gun2.visible = true

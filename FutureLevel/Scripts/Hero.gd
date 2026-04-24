extends CharacterBody2D 

var health = 100.0
const MAX_HEALTH = 100.0
@export var SPEED = 600.0
var previous_speed: float = SPEED
const JUMP_VELOCITY = -1100.0
const DOUBLE_JUMP_VELOCITY = -1300.0
const GRAVITY = 4000.0  
const COYOTE_TIME = 0.2  
const MAX_FALL_SPEED = 3500.0
const DOUBLE_JUMP := "CgkI_v7o0NMNEAIQBA"
var direction : Vector2 = Vector2.ZERO
@export var acceleration: float = 4000.0
@export var deceleration: float = 7000.0

# AdMob interstitial test ad unit
#const TEST_INTERSTITIAL_ANDROID := "ca-app-pub-3940256099942544/1033173712"
# Replace later with your real interstitial unit:
const REAL_INTERSTITIAL_ANDROID := "ca-app-pub-9308215462399709/5241273291"

var interstitial_ad: InterstitialAd = null
var interstitial_ad_load_callback := InterstitialAdLoadCallback.new()
var full_screen_callback := FullScreenContentCallback.new()
var game_over_ad_pending := false

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
@onready var marker_2d: Marker2D = $Gun/Marker2D
@onready var grenade_ability: Node = $GrenadeAbility
@onready var toss_hand: Marker2D = $TossHand

@export var throw_force: float = 500.0
@export_range(0.0, 1.0, 0.01) var lob_elevation: float = 0.35  
var facing_dir: Vector2 = Vector2.RIGHT  

var can_double_jump = false
var coyote_time_remaining = 0.0  
var is_double_jumping = false
var is_dead = false
var jump_effect_visible = false 
var is_walking: bool = false
var double_jump_achievement_sent := false

func _ready() -> void:
	Global.player = self
	health_bar.init_health(health)

	if Global.lives < 3:
		position = Global.checkpoint_position
	else: 
		position = Vector2(353.993, -306.008)

	if is_instance_valid(grenade_ability):
		if grenade_ability.has_signal("cooldown_started"):
			grenade_ability.connect("cooldown_started", Callable(self, "_on_grenade_cd_start"))
		if grenade_ability.has_signal("cooldown_ready"):
			grenade_ability.connect("cooldown_ready", Callable(self, "_on_grenade_cd_ready"))

	MobileAds.initialize()
	_setup_interstitial_callbacks()

	interstitial_ad_load_callback.on_ad_failed_to_load = _on_interstitial_ad_failed_to_load
	interstitial_ad_load_callback.on_ad_loaded = _on_interstitial_ad_loaded

	_load_interstitial()

func _setup_interstitial_callbacks() -> void:
	full_screen_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("Interstitial dismissed")
		_cleanup_interstitial()
		_show_game_over_screen()
		_load_interstitial()

	full_screen_callback.on_ad_failed_to_show_full_screen_content = func(ad_error: AdError) -> void:
		print("Failed to show interstitial: ", ad_error.message)
		_cleanup_interstitial()
		_show_game_over_screen()
		_load_interstitial()

	full_screen_callback.on_ad_showed_full_screen_content = func() -> void:
		print("Interstitial showed")

func _load_interstitial() -> void:
	if interstitial_ad:
		interstitial_ad.destroy()
		interstitial_ad = null

	InterstitialAdLoader.new().load(
		REAL_INTERSTITIAL_ANDROID,
		AdRequest.new(),
		interstitial_ad_load_callback
	)

func _on_interstitial_ad_failed_to_load(ad_error: LoadAdError) -> void:
	print("Interstitial failed to load: ", ad_error.message)

func _on_interstitial_ad_loaded(ad: InterstitialAd) -> void:
	print("Interstitial loaded")
	interstitial_ad = ad
	interstitial_ad.full_screen_content_callback = full_screen_callback

func _show_game_over_ad() -> void:
	if interstitial_ad != null:
		game_over_ad_pending = true
		interstitial_ad.show()
	else:
		print("No interstitial ready, opening game over normally")
		_show_game_over_screen()

func _cleanup_interstitial() -> void:
	if interstitial_ad:
		interstitial_ad.destroy()
		interstitial_ad = null

func take_damage(amount: int):
	if is_dead:
		return

	health -= amount
	animated_sprite_2d.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.2).timeout
	
	var knockback_force = Vector2(-180, -180)  
	velocity += knockback_force
	
	animated_sprite_2d.modulate = Color(1, 1, 1)
	health_bar.health = health

	if health <= 0.0:
		velocity = Vector2.ZERO
		_die()

func _die():
	if is_dead:
		return

	is_dead = true
	GameManager.register_player_death()
	Global.lives -= 1

	if Global.lives <= 0:
		_show_game_over_ad()
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
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
	else:
		coyote_time_remaining = COYOTE_TIME
		can_double_jump = true
		is_double_jumping = false
	
	move_and_slide()

	if SPEED > previous_speed:
		_on_speed_increase()

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
	super_sayain.visible = true 
	%Buffs.emit_speed_up()
	await get_tree().create_timer(1.0).timeout
	super_sayain.visible = false 

func handle_jumping(delta: float) -> void:
	if !is_on_floor():
		coyote_time_remaining -= delta

	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_time_remaining > 0.0:
			velocity.y = JUMP_VELOCITY
			can_double_jump = true
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
			
			if not double_jump_achievement_sent:
				double_jump_achievement_sent = true
				if playgames.is_available() and playgames.is_signed_in():
					playgames.unlock_achievement(DOUBLE_JUMP)
					print("Double jump achievement unlocked request sent")

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

func handle_movement(delta: float) -> void:
	var target_velocity_x = 0.0
	
	if Input.is_action_pressed("move_left"):
		target_velocity_x -= SPEED
	if Input.is_action_pressed("move_right"):
		target_velocity_x += SPEED

	if velocity.x < target_velocity_x:
		velocity.x += acceleration * delta
		velocity.x = min(velocity.x, target_velocity_x)
	elif velocity.x > target_velocity_x:
		velocity.x -= deceleration * delta
		velocity.x = max(velocity.x, target_velocity_x)

func _trigger_jump_effect() -> void:
	%JumpEffect.visible = true
	%JumpEffect.emitting = true
	%JumpEffect2.emitting = true
	
func _trigger_doublejump_effect() -> void:
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
		_show_game_over_ad()
	else:
		_respawn()

func _show_game_over_screen() -> void:
	game_over_ad_pending = false
	Engine.time_scale = 1.0

	const GAMEOVER = preload("res://Scenes/GameOver.tscn") 
	var new_gameover = GAMEOVER.instantiate()
	get_tree().current_scene.add_child(new_gameover)

func _on_game_over():
	_show_game_over_screen()

func _on_pick_up_gun_picked_up() -> void:
	%Gun2.set_collision_mask_value(3, true)
	%Gun2.visible = true

func update_facing(dir: Vector2) -> void:
	if dir.length() > 0.01:
		facing_dir = dir.normalized()

func _get_aim_dir() -> Vector2:
	var aim: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if aim.length() > 0.01:
		return (aim + Vector2(0, -lob_elevation)).normalized()

	var move: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move.length() > 0.01:
		facing_dir = move.normalized()
		return (facing_dir + Vector2(0, -lob_elevation)).normalized()

	var dir := (facing_dir + Vector2(0, -lob_elevation))
	if dir.length() <= 0.001:
		dir = Vector2.RIGHT + Vector2(0, -lob_elevation)
	return dir.normalized()

func _on_special_pressed() -> void:
	if Input.is_action_pressed("special"):
		var grenade_scene: PackedScene = preload("res://Scenes/granade.tscn")
		var g: RigidBody2D = grenade_scene.instantiate()
		g.global_position = %TossHand.global_position
		get_tree().current_scene.add_child(g)
		var dir := _get_aim_dir()
		g.throw(dir, throw_force)

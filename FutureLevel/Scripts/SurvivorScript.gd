extends CharacterBody2D

signal rank_changed(rank_index: int)
signal playerdeath

# Player properties
var health: float = 500.0
const MAX_HEALTH = 500
const VELOCITY = 1000
@export var SPEED: float = 500.0
@export var acceleration: float = 2200
@export var deceleration: float = 4000
const DEADZONE: float = 0.15  # small pad for sticks/float rounding

# If joystick scaling makes left/right weaker, bump X gain (ex: 1.25). Keep Y at 1.0.
@export var JOY_X_GAIN: float = 1.0
@export var JOY_Y_GAIN: float = 1.0

@onready var shadow: Sprite2D = $AnimatedSprite2D/Shadow
@onready var rank_1: Sprite2D = $Rank1
@onready var rank_2: Sprite2D = $Rank2
@onready var rank_3: Sprite2D = $Rank3
@onready var rank_4: Sprite2D = $Rank4
@onready var rank_5: Sprite2D = $Rank5
@onready var gun: Area2D = $Gun

const SECOND_GUN_SCENE := preload("res://Scenes/Gun.tscn")
const ORBITING_PLASMA_BALL_SCENE := preload("res://Scenes/OrbitingPlasmaBall.tscn")
const PRIMARY_GUN_LEFT_POSITION := Vector2(4, 3)
const PRIMARY_GUN_RIGHT_POSITION := Vector2(-4, 3)
const SECOND_GUN_LEFT_POSITION := Vector2(4, 5)
const SECOND_GUN_RIGHT_POSITION := Vector2(-4, 5)
const PLASMA_BALL_START_ANGLES := [-PI * 0.5, PI * 0.5, PI, 0.0]
const ACHIEVEMENT_MY_STRENGTH_IS_GROWING = "CgkI_v7o0NMNEAIQDg"
const ACHIEVEMENT_FURTHER_BEYOND = "CgkI_v7o0NMNEAIQDw"

var rank_3_achievement_sent := false
var rank_4_achievement_sent = false
var second_gun: Area2D = null
var orbiting_plasma_balls: Array[Area2D] = []

# Animation setup
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = %HealthBar
@onready var timer_2: Timer = $Timer2
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var is_dead: bool = false
var current_kills: int = 0
@export var rank_thresholds: Array = [50, 300, 400, 500, 600]
@export var fire_rates: Array = [0.20, 0.15, 0.10, 0.08, 0.05]

# Interstitial ad test unit
#const TEST_INTERSTITIAL_ANDROID := "ca-app-pub-3940256099942544/1033173712"
# Replace later with your real interstitial ad unit:
const REAL_INTERSTITIAL_ANDROID := "ca-app-pub-9308215462399709/5241273291"

var interstitial_ad: InterstitialAd = null
var interstitial_ad_load_callback := InterstitialAdLoadCallback.new()
var interstitial_full_screen_callback := FullScreenContentCallback.new()

func _ready() -> void:
	Global.player = self
	GameManager.connect("scene_kill_updated", Callable(self, "_on_game_manager_scene_kill_updated"))
	rank_changed.connect(Callable(self, "_on_rank_changed"))

	MobileAds.initialize()
	_setup_interstitial_callbacks()

	interstitial_ad_load_callback.on_ad_failed_to_load = _on_interstitial_ad_failed_to_load
	interstitial_ad_load_callback.on_ad_loaded = _on_interstitial_ad_loaded

	_load_interstitial_game_over_ad()

func take_damage(amount: int):
	if is_dead:
		return

	health -= amount
	health_bar.value = health

	await get_tree().create_timer(0.2).timeout
	health_bar.indeterminate = true
	animated_sprite_2d.self_modulate = Color(10, 0, 0)

	await get_tree().create_timer(0.2).timeout
	animated_sprite_2d.self_modulate = Color(1, 1, 1)
	health_bar.indeterminate = false

	if health <= 0:
		_die()

func _die():
	if is_dead:
		return

	is_dead = true
	emit_signal("playerdeath")
	animated_sprite_2d.play("death")
	audio_stream_player.play()
	timer_2.start()

func update_shooting_rate():
	for equipped_gun in _get_equipped_guns():
		if equipped_gun.has_method("stop_shooting"):
			equipped_gun.call("stop_shooting")

func equip_second_gun() -> bool:
	if has_second_gun():
		return false

	var new_gun := SECOND_GUN_SCENE.instantiate() as Area2D
	if new_gun == null:
		return false

	new_gun.name = "Gun2"
	new_gun.visible = true
	new_gun.show_behind_parent = gun.show_behind_parent
	new_gun.z_index = 1
	new_gun.collision_mask = gun.collision_mask
	new_gun.set("rate_of_fire", gun.get("rate_of_fire"))
	add_child(new_gun)

	second_gun = new_gun
	_position_equipped_guns()
	update_shooting_rate()
	return true

func has_second_gun() -> bool:
	return second_gun != null and is_instance_valid(second_gun)

func equip_orbiting_plasma_ball() -> bool:
	var current_tier := get_orbiting_plasma_ball_count()
	if current_tier >= PLASMA_BALL_START_ANGLES.size():
		return false

	var new_plasma_ball := ORBITING_PLASMA_BALL_SCENE.instantiate() as Area2D
	if new_plasma_ball == null:
		return false

	new_plasma_ball.name = "OrbitingPlasmaBall%d" % (current_tier + 1)
	new_plasma_ball.z_index = 3
	if new_plasma_ball.has_method("set_orbit_angle"):
		new_plasma_ball.call("set_orbit_angle", float(PLASMA_BALL_START_ANGLES[current_tier]))
	add_child(new_plasma_ball)

	orbiting_plasma_balls.append(new_plasma_ball)
	_sync_orbiting_plasma_balls()
	return true

func has_orbiting_plasma_ball() -> bool:
	return get_orbiting_plasma_ball_count() > 0

func can_equip_orbiting_plasma_ball() -> bool:
	return get_orbiting_plasma_ball_count() < PLASMA_BALL_START_ANGLES.size()

func get_orbiting_plasma_ball_count() -> int:
	return _get_valid_orbiting_plasma_balls().size()

func _get_valid_orbiting_plasma_balls() -> Array[Area2D]:
	var valid_plasma_balls: Array[Area2D] = []
	for plasma_ball in orbiting_plasma_balls:
		if plasma_ball != null and is_instance_valid(plasma_ball):
			valid_plasma_balls.append(plasma_ball)

	orbiting_plasma_balls = valid_plasma_balls
	return orbiting_plasma_balls

func _sync_orbiting_plasma_balls() -> void:
	var valid_plasma_balls := _get_valid_orbiting_plasma_balls()
	for index in range(valid_plasma_balls.size()):
		var plasma_ball := valid_plasma_balls[index]
		if plasma_ball.has_method("set_orbit_angle"):
			plasma_ball.call("set_orbit_angle", float(PLASMA_BALL_START_ANGLES[index]))

func _get_equipped_guns() -> Array[Area2D]:
	var equipped_guns: Array[Area2D] = []
	if gun != null and is_instance_valid(gun):
		equipped_guns.append(gun)
	if has_second_gun():
		equipped_guns.append(second_gun)
	return equipped_guns

func rank_up():
	for i in range(rank_thresholds.size()):
		if current_kills < rank_thresholds[i]:
			_update_rank_display(i)

			if i >= 2 and not rank_3_achievement_sent:
				rank_3_achievement_sent = true
				if playgames.is_available() and playgames.is_signed_in():
					playgames.unlock_achievement(ACHIEVEMENT_MY_STRENGTH_IS_GROWING)
					print("Rank 3 achievement unlock request sent")

			if i >= 3 and not rank_4_achievement_sent:
				rank_4_achievement_sent = true
				if playgames.is_available() and playgames.is_signed_in():
					playgames.unlock_achievement(ACHIEVEMENT_FURTHER_BEYOND)
					print("Rank 4 achievement unlock request sent")

			emit_signal("rank_changed", i)
			return

	var max_rank_index := rank_thresholds.size()
	_update_rank_display(max_rank_index)

	if max_rank_index >= 2 and not rank_3_achievement_sent:
		rank_3_achievement_sent = true
		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_MY_STRENGTH_IS_GROWING)
			print("Rank 3 achievement unlock request sent")

	if max_rank_index >= 3 and not rank_4_achievement_sent:
		rank_4_achievement_sent = true
		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_FURTHER_BEYOND)
			print("Rank 4 achievement unlock request sent")

	emit_signal("rank_changed", max_rank_index)

func _update_rank_display(rank_index: int) -> void:
	if rank_index >= fire_rates.size():
		rank_index = fire_rates.size() - 1

	for equipped_gun in _get_equipped_guns():
		equipped_gun.set("rate_of_fire", fire_rates[rank_index])
	update_shooting_rate()

	rank_1.visible = rank_index == 0
	rank_2.visible = rank_index == 1
	rank_3.visible = rank_index == 2
	rank_4.visible = rank_index == 3
	rank_5.visible = rank_index == 4

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var input_dir: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down",
		DEADZONE
	)

	input_dir = Vector2(input_dir.x * JOY_X_GAIN, input_dir.y * JOY_Y_GAIN)
	input_dir = input_dir.limit_length(1.0)

	var has_input := input_dir.length() > 0.0
	var target_velocity := Vector2.ZERO

	if has_input:
		target_velocity = input_dir * SPEED
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		if velocity.length() < 5.0:
			velocity = Vector2.ZERO

	move_and_slide()
	flip_sprite()
	handle_collisions(delta)
	handle_player_animation()

func handle_collisions(delta: float):
	const DAMAGE_RATE = 10.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	health_bar.value = health

	if overlapping_mobs.size() > 0:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		health_bar.value = health

	if health <= 0:
		_die()

func handle_player_animation() -> void:
	if velocity.length() > 0:
		if animation_player.current_animation != "walk":
			animation_player.play("walk")
	else:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")

func flip_sprite() -> void:
	if velocity.x < -3:
		animated_sprite_2d.flip_h = true
		_position_equipped_guns()
		shadow.position = Vector2(5, 34)
		%SuperSayain.position = Vector2(19.6, 36.8)
		%SuperSayain4.position = Vector2(19.2, 33.7)
	elif velocity.x > 3:
		animated_sprite_2d.flip_h = false
		_position_equipped_guns()
		shadow.position = Vector2(-9.5, 34)
		%SuperSayain.position = Vector2(-5.0, 32.6)
		%SuperSayain4.position = Vector2(-3.8, 28.8)

func _position_equipped_guns() -> void:
	if animated_sprite_2d.flip_h:
		gun.position = PRIMARY_GUN_LEFT_POSITION
		if has_second_gun():
			second_gun.position = SECOND_GUN_LEFT_POSITION
	else:
		gun.position = PRIMARY_GUN_RIGHT_POSITION
		if has_second_gun():
			second_gun.position = SECOND_GUN_RIGHT_POSITION

func _on_timer_2_timeout() -> void:
	_show_game_over_ad()

func _game_over():
	GameManager.reset_scene_kills()

	const GAMEOVER = preload("res://Scenes/GameOver.tscn")
	var new_gameover = GAMEOVER.instantiate()
	add_child(new_gameover)

func _show_game_over_ad() -> void:
	if interstitial_ad != null:
		interstitial_ad.show()
	else:
		print("No interstitial ad ready, opening game over")
		_game_over()
		_load_interstitial_game_over_ad()

func _setup_interstitial_callbacks() -> void:
	interstitial_full_screen_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("Interstitial dismissed")
		_cleanup_interstitial_ad()
		_game_over()
		_load_interstitial_game_over_ad()

	interstitial_full_screen_callback.on_ad_failed_to_show_full_screen_content = func(ad_error: AdError) -> void:
		print("Interstitial failed to show: ", ad_error.message)
		_cleanup_interstitial_ad()
		_game_over()
		_load_interstitial_game_over_ad()

	interstitial_full_screen_callback.on_ad_showed_full_screen_content = func() -> void:
		print("Interstitial showed")

func _load_interstitial_game_over_ad() -> void:
	if interstitial_ad:
		interstitial_ad.destroy()
		interstitial_ad = null

	InterstitialAdLoader.new().load(
		REAL_INTERSTITIAL_ANDROID,
		AdRequest.new(),
		interstitial_ad_load_callback
	)

func _on_interstitial_ad_failed_to_load(ad_error: LoadAdError) -> void:
	print("Interstitial ad failed to load: ", ad_error.message)

func _on_interstitial_ad_loaded(ad: InterstitialAd) -> void:
	print("Interstitial ad loaded")
	interstitial_ad = ad
	interstitial_ad.full_screen_content_callback = interstitial_full_screen_callback

func _cleanup_interstitial_ad() -> void:
	if interstitial_ad:
		interstitial_ad.destroy()
		interstitial_ad = null

func _on_spawn_timer_timeout() -> void:
	const SPAWN = preload("res://Scenes/SpawnCircle.tscn")
	const BIGSPAWN = preload("res://Scenes/BigSpawnCircle.tscn")

	var new_big = BIGSPAWN.instantiate()
	var new_spawn = SPAWN.instantiate()

	new_big.position = global_position
	new_spawn.position = global_position

	add_child(new_big)
	add_child(new_spawn)

func _on_game_manager_scene_kill_updated(kills: int) -> void:
	current_kills = kills
	rank_up()

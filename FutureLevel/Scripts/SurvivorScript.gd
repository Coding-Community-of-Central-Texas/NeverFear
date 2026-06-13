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
const LASER_SNIPER_SCENE := preload("res://Scenes/LaserSniper.tscn")
const ORBITING_PLASMA_BALL_SCENE := preload("res://Scenes/OrbitingPlasmaBall.tscn")
const PRIMARY_GUN_LEFT_POSITION := Vector2(4, 3)
const PRIMARY_GUN_RIGHT_POSITION := Vector2(-4, 3)
const SECOND_GUN_LEFT_POSITION := Vector2(4, 5)
const SECOND_GUN_RIGHT_POSITION := Vector2(-4, 5)
const LASER_SNIPER_LEFT_POSITION := Vector2(4, 7)
const LASER_SNIPER_RIGHT_POSITION := Vector2(-4, 7)
const PLASMA_BALL_START_ANGLES := [-PI * 0.5, PI * 0.5, PI, 0.0]
const ACHIEVEMENT_MY_STRENGTH_IS_GROWING = "CgkI_v7o0NMNEAIQDg"
const ACHIEVEMENT_FURTHER_BEYOND = "CgkI_v7o0NMNEAIQDw"

var rank_3_achievement_sent := false
var rank_4_achievement_sent = false
var second_gun: Area2D = null
var laser_sniper: Area2D = null
var orbiting_plasma_balls: Array[Area2D] = []

# Animation setup
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimatedSprite2D/AnimationPlayer
@onready var health_bar: ProgressBar = %HealthBar
@onready var timer_2: Timer = $Timer2
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

const SHOTGUN_SCENE := preload("res://Scenes/Shotgun.tscn")
var is_dead: bool = false
var current_kills: int = 0
@export var rank_thresholds: Array = [50, 300, 400, 500, 600]
@export var fire_rates: Array = [0.20, 0.15, 0.10, 0.08, 0.05]
var shotgun: Area2D = null
var shotgun_equipped := false
var laser_sniper_equipped := false

func _ready() -> void:
	Global.player = self
	shotgun = get_node_or_null("Shotgun") as Area2D
	_set_shotgun_enabled(false)
	GameManager.connect("scene_kill_updated", Callable(self, "_on_game_manager_scene_kill_updated"))
	rank_changed.connect(Callable(self, "_on_rank_changed"))

	Ads.prepare_game_over_ad()

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
	if has_shotgun() and shotgun.has_method("stop_shooting"):
		shotgun.call("stop_shooting")
	if has_laser_sniper() and laser_sniper.has_method("stop_shooting"):
		laser_sniper.call("stop_shooting")

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

func equip_shotgun() -> bool:
	if has_shotgun():
		return false

	if shotgun == null or not is_instance_valid(shotgun):
		shotgun = SHOTGUN_SCENE.instantiate() as Area2D
		if shotgun == null:
			return false

		shotgun.name = "Shotgun"
		shotgun.z_index = 0
		add_child(shotgun)

	shotgun_equipped = true
	_set_shotgun_enabled(true)
	_position_equipped_guns()
	return true

func has_shotgun() -> bool:
	return shotgun_equipped and shotgun != null and is_instance_valid(shotgun)

func _set_shotgun_enabled(is_enabled: bool) -> void:
	if shotgun == null or not is_instance_valid(shotgun):
		return

	if not is_enabled and shotgun.has_method("stop_shooting"):
		shotgun.call("stop_shooting")

	shotgun.visible = is_enabled
	shotgun.monitoring = is_enabled
	shotgun.monitorable = is_enabled
	shotgun.process_mode = Node.PROCESS_MODE_INHERIT if is_enabled else Node.PROCESS_MODE_DISABLED

func equip_laser_sniper() -> bool:
	if has_laser_sniper():
		return false

	if laser_sniper == null or not is_instance_valid(laser_sniper):
		laser_sniper = LASER_SNIPER_SCENE.instantiate() as Area2D
		if laser_sniper == null:
			return false

		laser_sniper.name = "LaserSniper"
		laser_sniper.z_index = 2
		add_child(laser_sniper)

	laser_sniper_equipped = true
	_set_laser_sniper_enabled(true)
	_position_equipped_guns()
	return true

func has_laser_sniper() -> bool:
	return laser_sniper_equipped and laser_sniper != null and is_instance_valid(laser_sniper)

func _set_laser_sniper_enabled(is_enabled: bool) -> void:
	if laser_sniper == null or not is_instance_valid(laser_sniper):
		return

	if not is_enabled and laser_sniper.has_method("stop_shooting"):
		laser_sniper.call("stop_shooting")

	laser_sniper.visible = is_enabled
	laser_sniper.monitoring = is_enabled
	laser_sniper.monitorable = is_enabled
	laser_sniper.process_mode = Node.PROCESS_MODE_INHERIT if is_enabled else Node.PROCESS_MODE_DISABLED

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


			if i >= 3 and not rank_4_achievement_sent:
				rank_4_achievement_sent = true
				if playgames.is_available() and playgames.is_signed_in():
					playgames.unlock_achievement(ACHIEVEMENT_FURTHER_BEYOND)


			emit_signal("rank_changed", i)
			return

	var max_rank_index := rank_thresholds.size()
	_update_rank_display(max_rank_index)

	if max_rank_index >= 2 and not rank_3_achievement_sent:
		rank_3_achievement_sent = true
		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_MY_STRENGTH_IS_GROWING)


	if max_rank_index >= 3 and not rank_4_achievement_sent:
		rank_4_achievement_sent = true
		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_FURTHER_BEYOND)


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
		_play_player_animation("walk")
	else:
		_play_player_animation("idle")

func _play_player_animation(animation_name: StringName) -> void:
	if animation_player == null or not animation_player.has_animation(animation_name):
		return
	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)

func flip_sprite() -> void:
	if velocity.x < -3:
		animated_sprite_2d.flip_h = true
		_position_equipped_guns()
		shadow.position = Vector2(5, 34)
		%SuperSayain4.position = Vector2(19.2, 33.7)
	elif velocity.x > 3:
		animated_sprite_2d.flip_h = false
		_position_equipped_guns()
		shadow.position = Vector2(-9.5, 34)
		%SuperSayain4.position = Vector2(-3.8, 28.8)

func _position_equipped_guns() -> void:
	if animated_sprite_2d.flip_h:
		gun.position = PRIMARY_GUN_LEFT_POSITION
		if has_second_gun():
			second_gun.position = SECOND_GUN_LEFT_POSITION
		if has_shotgun():
			shotgun.position = PRIMARY_GUN_LEFT_POSITION
		if has_laser_sniper():
			laser_sniper.position = LASER_SNIPER_LEFT_POSITION
	else:
		gun.position = PRIMARY_GUN_RIGHT_POSITION
		if has_second_gun():
			second_gun.position = SECOND_GUN_RIGHT_POSITION
		if has_shotgun():
			shotgun.position = PRIMARY_GUN_RIGHT_POSITION
		if has_laser_sniper():
			laser_sniper.position = LASER_SNIPER_RIGHT_POSITION

func _on_timer_2_timeout() -> void:
	_show_game_over_ad()

func _game_over():
	GameManager.reset_scene_kills()

	const GAMEOVER = preload("res://Scenes/GameOver.tscn")
	var new_gameover = GAMEOVER.instantiate()
	add_child(new_gameover)

func _show_game_over_ad() -> void:
	Ads.show_game_over_interstitial(Callable(self, "_game_over"))

func _on_spawn_timer_timeout() -> void:
	if _get_pool_manager() != null:
		for spawner in get_tree().get_nodes_in_group("gauntlet_spawner"):
			if spawner.has_method("spawn_wave"):
				spawner.call("spawn_wave")
		return

	const SPAWN = preload("res://Scenes/SpawnCircle.tscn")
	const BIGSPAWN = preload("res://Scenes/BigSpawnCircle.tscn")

	var new_big = BIGSPAWN.instantiate()
	var new_spawn = SPAWN.instantiate()

	new_big.position = global_position
	new_spawn.position = global_position

	add_child(new_big)
	add_child(new_spawn)

func _get_pool_manager() -> Node:
	return get_tree().get_first_node_in_group("survival_pool_manager")

func _on_game_manager_scene_kill_updated(kills: int) -> void:
	current_kills = kills
	rank_up()

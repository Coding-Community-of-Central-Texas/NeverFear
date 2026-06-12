extends Area2D

signal add_cash
signal request_pool_return(instance: Node)

const DEFAULT_CASH_PICKUP_MIN := 1000
const DEFAULT_CASH_PICKUP_MAX := 10000

var GRAVITY = 200
var MAX_FALL_SPEED = 250.0# Maximum falling speed
@export var magnet_radius: float = 220.0
@export var magnet_min_speed: float = 180.0
@export var magnet_max_speed: float = 820.0
@export var pickup_radius: float = 28.0

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var ground_ray_cast_2d: RayCast2D = $GroundRayCast2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var queue_timer: Timer = $QueueTimer

var pickup_song: AudioStream = preload("res://assets/FutrueSFX/PickUp.wav")
var velocity = Vector2.ZERO
var is_collected := false
var is_magnetized := false
var has_randomized_power_up := false
var active := true
var pooled := false

enum PowerUpType {
	CASH,
	SPEED, 
	HEALTH, 
	LIVES
}

var power_up_type: PowerUpType = PowerUpType.CASH
var power_up_value: float = 0.0

func _ready() -> void:
	%CashSpin.play("spin")
	ground_ray_cast_2d.enabled = true
	audio_stream_player_2d.stream = pickup_song
	animation_player.play("heart")
	if not has_randomized_power_up:
		randomize_power_up()
	_apply_power_up_visuals()

func set_pooled(value: bool) -> void:
	pooled = value

func activate(spawn_position: Vector2, data: Dictionary = {}) -> void:
	active = true
	is_collected = false
	is_magnetized = false
	has_randomized_power_up = false
	velocity = Vector2.ZERO
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_physics_process(true)
	global_position = spawn_position
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	collision_shape_2d.set_deferred("disabled", false)
	ground_ray_cast_2d.enabled = true
	audio_stream_player_2d.stream = pickup_song
	%CashSpin.play("spin")
	animation_player.play("heart")
	if bool(data.get("randomize_power_up", true)):
		randomize_power_up()
	else:
		_apply_power_up_visuals()
	if queue_timer:
		queue_timer.start()

func deactivate(return_to_pool: bool = true) -> void:
	if not active and return_to_pool:
		return

	active = false
	is_collected = false
	is_magnetized = false
	velocity = Vector2.ZERO
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)
	process_mode = Node.PROCESS_MODE_DISABLED
	if queue_timer:
		queue_timer.stop()
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)
	if ground_ray_cast_2d:
		ground_ray_cast_2d.enabled = false
	if audio_stream_player_2d:
		audio_stream_player_2d.stop()

	if pooled:
		if return_to_pool:
			request_pool_return.emit(self)
	elif return_to_pool:
		queue_free()

func randomize_power_up() -> void:
	has_randomized_power_up = true
	power_up_value = 0.0
	# Define weighted probabilities for each power-up type
	var weights = {
		PowerUpType.CASH: 80,
		PowerUpType.SPEED: 5,  
		PowerUpType.HEALTH: 10,  
		PowerUpType.LIVES: 5   
	}
	# Generate a random number between 0 and the total weight
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight
	var random_number = randi() % total_weight
	# Determine the power-up type based on the random number
	var cumulative_weight = 0
	for power_up in weights:
		cumulative_weight += weights[power_up]
		if random_number < cumulative_weight:
			power_up_type = power_up
			break
	# Randomize the power-up value based on its type
	match power_up_type:
		PowerUpType.CASH:
			pass
		PowerUpType.SPEED:
			power_up_value = randi_range(15, 40)
		PowerUpType.HEALTH:
			power_up_value = randi_range(10, 60)  
		PowerUpType.LIVES:
			power_up_value = randi_range(1, 2)   
	if is_node_ready():
		_apply_power_up_visuals()

func _apply_power_up_visuals() -> void:
	%CashSpin.visible = power_up_type == PowerUpType.CASH
	%Star.visible = power_up_type == PowerUpType.SPEED
	%Health.visible = power_up_type == PowerUpType.HEALTH
	%Heart.visible = power_up_type == PowerUpType.LIVES

func _physics_process(delta: float):
	if not active or is_collected:
		return
	if _apply_magnet_pull(delta):
		return
	if get_tree().current_scene.is_in_group("Legacy"):
		if !ground_ray_cast_2d.is_colliding():
			velocity.y += GRAVITY * delta
			velocity.y = min(velocity.y, MAX_FALL_SPEED)  # Cap the falling speed
			position += velocity * delta
		else:
			velocity.y = 0  # Stop falling when the ray detects the ground

func _apply_magnet_pull(delta: float) -> bool:
	var player := _get_player()
	if player == null or magnet_radius <= 0.0:
		return false

	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player <= pickup_radius:
		_collect(player)
		return true

	if not is_magnetized and distance_to_player > magnet_radius:
		return false
	is_magnetized = true

	var pull_percent: float = 1.0 - clampf(distance_to_player / magnet_radius, 0.0, 1.0)
	var pull_speed: float = lerpf(magnet_min_speed, magnet_max_speed, pull_percent)
	global_position = global_position.move_toward(player.global_position, pull_speed * delta)
	if global_position.distance_to(player.global_position) <= pickup_radius:
		_collect(player)
	return true

func _get_player() -> Node2D:
	if Global.player is Node2D and is_instance_valid(Global.player):
		return Global.player
	return null

func _on_body_entered(body):
	if not active or is_collected:
		return
	if body.is_in_group("player"):
		_collect(body)

func _collect(body: Node) -> void:
	if not active or is_collected:
		return
	if body == null or not body.is_in_group("player"):
		return

	is_collected = true
	is_magnetized = false
	velocity = Vector2.ZERO
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)
	if queue_timer:
		queue_timer.stop()
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)
	if ground_ray_cast_2d:
		ground_ray_cast_2d.enabled = false

	if audio_stream_player_2d.stream != null:
		audio_stream_player_2d.play()

	if power_up_type == PowerUpType.CASH:
		emit_signal("add_cash")
	else:
		apply_power_up()

	if audio_stream_player_2d.stream == null:
		deactivate()

func apply_power_up():
	var original_speed = Global.player.SPEED
	var original_health = Global.player.health
	var original_lives = Global.lives
	
	match power_up_type:
		PowerUpType.SPEED:
			Global.player.SPEED += power_up_value
		PowerUpType.HEALTH:
			Global.player.health = min(Global.player.MAX_HEALTH, Global.player.health + power_up_value)
		PowerUpType.LIVES:
			Global.lives += power_up_value
			GameManager.check_lives_achievement()

func _on_audio_stream_player_2d_finished() -> void:
	deactivate()

func _on_add_cash() -> void:
	GameManager.add_cash(_get_cash_pickup_amount())

func _get_cash_pickup_amount() -> int:
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("get_cash_pickup_amount"):
		return int(current_scene.call("get_cash_pickup_amount"))

	return randi_range(DEFAULT_CASH_PICKUP_MIN, DEFAULT_CASH_PICKUP_MAX)

func _on_queue_timer_timeout() -> void:
	deactivate()

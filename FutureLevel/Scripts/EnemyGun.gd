extends Area2D

@export var rate_of_fire: float = 1.5
@export var aim_update_interval: float = 0.08
@onready var timer: Timer = $Timer
@onready var shootingpoint: Marker2D = %shootingpoint
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


var shooting = false  # Whether shooting is active or not
var aim_timer := 0.0
var cached_target: Node2D = null
var cached_aim_direction := Vector2.ZERO

func _ready() -> void:
	_configure_aim_interval()
	reset_aim_state()

# This function is called when the timer times out (i.e., it's time to shoot)
func _on_timer_timeout():
	if shooting:  # Only shoot if we are still actively shooting
		shoot()

# Called every frame in the physics process
func _physics_process(delta):
	aim_timer -= delta
	if aim_timer > 0.0:
		return

	update_aim_decision()
	aim_timer = randf_range(aim_update_interval * 0.85, aim_update_interval * 1.15)

# Function to handle shooting
func shoot():
	const BULLET = preload("res://Scenes/EnemyBullet.tscn")
	var direction := cached_aim_direction
	if direction == Vector2.ZERO:
		update_aim_decision()
		direction = cached_aim_direction
	if direction == Vector2.ZERO:
		return

	var pool_manager := _get_pool_manager()
	if pool_manager != null and pool_manager.has_method("spawn_enemy_bullet"):
		var pooled_bullet: Node = pool_manager.call("spawn_enemy_bullet", shootingpoint.global_position, direction, direction.angle())
		if pooled_bullet != null:
			audio_stream_player_2d.play()
			return
		return

	var new_bullet = BULLET.instantiate()
	new_bullet.global_position = shootingpoint.global_position
	if direction != Vector2.ZERO:
		new_bullet.rotation = direction.angle()
		new_bullet.set_direction(direction)
	get_tree().current_scene.add_child(new_bullet)
	audio_stream_player_2d.play()

func stop_shooting() -> void:
	shooting = false
	timer.stop()
	reset_aim_state()

func _get_pool_manager() -> Node:
	return get_tree().get_first_node_in_group("survival_pool_manager")

func reset_aim_state() -> void:
	cached_target = null
	cached_aim_direction = Vector2.ZERO
	aim_timer = randf_range(0.0, maxf(aim_update_interval, 0.01))

func update_aim_decision() -> void:
	var bodies_in_range := get_overlapping_bodies()
	var target_player := get_best_target()
	if bodies_in_range.is_empty() or not _is_valid_target(target_player):
		cached_target = null
		cached_aim_direction = Vector2.ZERO
		if shooting:
			shooting = false
			timer.stop()
		return

	cached_target = target_player
	var to_target := cached_target.global_position - shootingpoint.global_position
	if to_target.length_squared() > 0.001:
		cached_aim_direction = to_target.normalized()
		look_at(cached_target.global_position)
	else:
		cached_aim_direction = Vector2.ZERO

	if not shooting:
		shooting = true
		timer.start(rate_of_fire)

func get_best_target() -> Node2D:
	var player_candidate = Global.player
	if player_candidate is Node2D and is_instance_valid(player_candidate):
		return player_candidate
	return null

func _configure_aim_interval() -> void:
	aim_update_interval = maxf(0.02, aim_update_interval + randf_range(-0.015, 0.015))
	if OS.get_name() == "iOS" or OS.get_name() == "Android":
		aim_update_interval *= 1.25

func _is_valid_target(target: Node) -> bool:
	return target is Node2D and is_instance_valid(target)

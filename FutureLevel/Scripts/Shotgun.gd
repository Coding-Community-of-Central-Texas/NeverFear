extends Area2D

@export var rate_of_fire: float = 0.55
@export_range(1, 21, 2) var pellet_count: int = 7
@export_range(0.0, 90.0, 0.1) var spread_degrees: float = 28.0
@export_range(0.0, 12.0, 0.1) var cluster_radius: float = 2.0
@export_range(0.0, 18.0, 0.1) var spread_jitter_degrees: float = 3.5
@export var default_range_scale: Vector2 = Vector2(1, 1)
@export var bullet_scene: PackedScene = preload("res://Scenes/ShotgunPellet.tscn")

@onready var shootingpoint: Marker2D = %shootingpoint
@onready var timer: Timer = $Timer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var muzzle_flash: CPUParticles2D = %Muzzleflash

var shooting := false

func _ready() -> void:
	randomize()
	collision_shape.scale = default_range_scale
	timer.wait_time = rate_of_fire

func set_range(new_scale: Vector2) -> void:
	collision_shape.scale = new_scale

func _on_timer_timeout() -> void:
	if shooting:
		shoot()

func _physics_process(_delta: float) -> void:
	var target_enemy := _get_target_enemy()
	if target_enemy != null:
		look_at(target_enemy.global_position)
		if not shooting:
			shooting = true
			shoot()
			timer.start(rate_of_fire)
	else:
		stop_shooting()

func shoot() -> void:
	if bullet_scene == null:
		return

	var pellets: int = maxi(1, pellet_count)
	var base_rotation: float = shootingpoint.global_rotation
	var pool_manager := _get_pool_manager()

	for pellet_index in range(pellets):
		var spread_offset: float = _get_pellet_angle_offset(pellet_index, pellets)
		var cluster_offset: Vector2 = _get_cluster_offset()
		var speed_multiplier: float = randf_range(0.92, 1.08)
		var spawn_position := shootingpoint.global_position + cluster_offset

		if pool_manager != null and pool_manager.has_method("spawn_shotgun_pellet"):
			var pooled_pellet: Node = pool_manager.call(
				"spawn_shotgun_pellet",
				spawn_position,
				base_rotation,
				{
					"spread_offset": spread_offset,
					"speed_multiplier": speed_multiplier,
				}
			)
			if pooled_pellet != null:
				continue
			continue

		var new_bullet := bullet_scene.instantiate() as Area2D
		if new_bullet == null:
			continue

		new_bullet.global_position = shootingpoint.global_position + cluster_offset
		new_bullet.global_rotation = base_rotation

		if new_bullet.has_method("configure"):
			new_bullet.call("configure", base_rotation, spread_offset, speed_multiplier)

		get_tree().current_scene.add_child(new_bullet)

	audio_stream_player.play()

func stop_shooting() -> void:
	shooting = false
	muzzle_flash.emitting = false
	timer.stop()

func _get_target_enemy() -> Node2D:
	for body in get_overlapping_bodies():
		if body is Node2D and body.is_in_group("enemy"):
			return body

	return null

func _get_pellet_angle_offset(pellet_index: int, pellets: int) -> float:
	if pellets <= 1:
		return 0.0

	var spread_radians := deg_to_rad(spread_degrees)
	var step := spread_radians / float(pellets - 1)
	var base_offset := -spread_radians * 0.5 + step * float(pellet_index)
	var jitter := deg_to_rad(randf_range(-spread_jitter_degrees, spread_jitter_degrees))
	var max_offset := spread_radians * 0.5
	return clampf(base_offset + jitter, -max_offset, max_offset)

func _get_cluster_offset() -> Vector2:
	if cluster_radius <= 0.0:
		return Vector2.ZERO

	var cluster_angle: float = randf_range(0.0, TAU)
	var cluster_distance: float = randf_range(0.0, cluster_radius)
	return Vector2.RIGHT.rotated(cluster_angle) * cluster_distance

func _get_pool_manager() -> Node:
	return get_tree().get_first_node_in_group("survival_pool_manager")

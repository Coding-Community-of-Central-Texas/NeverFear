extends Area2D

@export var rate_of_fire: float = 1.25
@export var blast_range: float = 1200.0
@export var blast_damage: int = 35
@export var beam_width: float = 18.0
@export var beam_visible_time: float = 0.08
@export var default_range_scale: Vector2 = Vector2(1, 1)
@export var target_far_enemies: bool = true

@onready var shootingpoint: Marker2D = %shootingpoint
@onready var timer: Timer = $Timer
@onready var beam_timer: Timer = $BeamTimer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var muzzle_flash: CPUParticles2D = %Muzzleflash
@onready var laser_glow: Line2D = %LaserGlow
@onready var laser_core: Line2D = %LaserCore
@onready var laser_impact: CPUParticles2D = %LaserImpact

var shooting := false

func _ready() -> void:
	collision_shape.scale = default_range_scale
	timer.wait_time = rate_of_fire
	beam_timer.wait_time = beam_visible_time
	_hide_laser_beam()

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
	var direction := Vector2.RIGHT.rotated(shootingpoint.global_rotation).normalized()
	_damage_laser_path(direction)
	_show_laser_beam(direction)
	audio_stream_player.play()

func stop_shooting() -> void:
	shooting = false
	muzzle_flash.emitting = false
	timer.stop()

func _get_target_enemy() -> Node2D:
	var selected_enemy: Node2D = null
	var selected_distance_sq := INF
	if target_far_enemies:
		selected_distance_sq = -INF

	for body in get_overlapping_bodies():
		if not (body is Node2D):
			continue
		if not body.is_in_group("enemy"):
			continue

		var enemy_node := body as Node2D
		var distance_sq := global_position.distance_squared_to(enemy_node.global_position)
		var is_better_target := false
		if target_far_enemies:
			is_better_target = distance_sq > selected_distance_sq
		else:
			is_better_target = distance_sq < selected_distance_sq
		if is_better_target:
			selected_enemy = enemy_node
			selected_distance_sq = distance_sq

	return selected_enemy

func _damage_laser_path(direction: Vector2) -> void:
	var origin := shootingpoint.global_position
	var already_hit: Array[Node2D] = []

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not (enemy is Node2D):
			continue
		var enemy_node := enemy as Node2D
		if already_hit.has(enemy_node):
			continue

		var to_enemy := enemy_node.global_position - origin
		var forward_distance := to_enemy.dot(direction)
		if forward_distance < 0.0 or forward_distance > blast_range:
			continue

		var sideways_distance := absf(to_enemy.cross(direction))
		if sideways_distance > beam_width:
			continue

		already_hit.append(enemy_node)
		if enemy_node.has_method("take_damage"):
			enemy_node.call("take_damage", blast_damage)

func _show_laser_beam(direction: Vector2) -> void:
	var points := PackedVector2Array([Vector2.ZERO, Vector2(blast_range, 0.0)])
	_configure_beam_line(laser_glow, points)
	_configure_beam_line(laser_core, points)

	var impact_position := shootingpoint.global_position + direction * blast_range
	laser_impact.global_position = impact_position
	laser_impact.global_rotation = shootingpoint.global_rotation
	laser_impact.restart()
	laser_impact.emitting = true
	muzzle_flash.emitting = true
	beam_timer.start(beam_visible_time)

func _configure_beam_line(line: Line2D, points: PackedVector2Array) -> void:
	line.global_position = shootingpoint.global_position
	line.global_rotation = shootingpoint.global_rotation
	line.points = points
	line.visible = true

func _hide_laser_beam() -> void:
	laser_glow.visible = false
	laser_core.visible = false
	laser_impact.emitting = false

func _on_beam_timer_timeout() -> void:
	_hide_laser_beam()
	muzzle_flash.emitting = false

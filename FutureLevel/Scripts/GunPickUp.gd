extends Area2D
signal picked_up

@export var magnet_radius: float = 220.0
@export var magnet_min_speed: float = 180.0
@export var magnet_max_speed: float = 820.0

var is_collected := false
var is_magnetized := false

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	_apply_magnet_pull(delta)

func _apply_magnet_pull(delta: float) -> bool:
	var player := _get_player()
	if player == null or magnet_radius <= 0.0:
		return false

	var distance_to_player: float = global_position.distance_to(player.global_position)
	if not is_magnetized and distance_to_player > magnet_radius:
		return false
	is_magnetized = true

	var pull_percent: float = 1.0 - clampf(distance_to_player / magnet_radius, 0.0, 1.0)
	var pull_speed: float = lerpf(magnet_min_speed, magnet_max_speed, pull_percent)
	global_position = global_position.move_toward(player.global_position, pull_speed * delta)
	return true

func _get_player() -> Node2D:
	var player = Global.player
	if player is Node2D and is_instance_valid(player):
		return player
	return null

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.is_in_group("player"):
		is_collected = true
		emit_signal("picked_up")
		queue_free()

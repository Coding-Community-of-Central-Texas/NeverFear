extends Area2D

@export var rate_of_fire: float = 0.15
@export var default_range_scale: Vector2 = Vector2(1, 1)  # Rate of fire: 0.15 seconds between shots (5 shots per second)
@onready var shootingpoint: Node2D = %shootingpoint
@onready var timer: Timer = $Timer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite
@onready var rifle: Sprite2D = $gunpivot/Rifle


var shooting = false  # Whether shooting is active or not

func on_ready():
	#%Smoke.visible = false
	collision_shape.scale = default_range_scale
# This function is called when the timer times out (i.e., it's time to shoot)
func set_range(new_scale: Vector2) -> void:
	collision_shape.scale = new_scale

func _on_timer_timeout():
	if shooting:  # Only shoot if we are still actively shooting
		shoot()

# Called every frame in the physics process
func _physics_process(_delta: float):
	var enemies_in_range = get_overlapping_bodies()
	if enemies_in_range.size() > 0:
		# There are enemies in range, look at the first one
		var target_enemy = enemies_in_range.front()
		look_at(target_enemy.global_position)
		
		# If we are not already shooting, start the shooting process
		if not shooting:
			shooting = true
			timer.start(rate_of_fire)  # Start the shooting timer
	else:
		# No enemies in range, stop shooting
		if shooting:
			shooting = false
			%Muzzleflash.emitting = false
			timer.stop()  # Stop the shooting timer when no enemies are detected

# Function to handle shooting
func shoot():
	%Muzzleflash.emitting = true 
	const BULLET = preload("res://Scenes/Bullet.tscn")
	var pool_manager := _get_pool_manager()
	if pool_manager != null and pool_manager.has_method("spawn_player_bullet"):
		var pooled_bullet: Node = pool_manager.call("spawn_player_bullet", shootingpoint.global_position, shootingpoint.global_rotation)
		if pooled_bullet != null:
			audio_stream_player.play()
		return

	var new_bullet = BULLET.instantiate()
	new_bullet.global_position = shootingpoint.global_position
	new_bullet.global_rotation = shootingpoint.global_rotation
	shootingpoint.add_child(new_bullet)
	audio_stream_player.play()

func stop_shooting():
	shooting = false
	timer.stop()

func _get_pool_manager() -> Node:
	return get_tree().get_first_node_in_group("survival_pool_manager")

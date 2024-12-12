extends Area2D

@export var rate_of_fire: float = 0.5
@onready var timer: Timer = $Timer
@onready var shootingpoint: Marker2D = %shootingpoint
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


var shooting = false  # Whether shooting is active or not

# This function is called when the timer times out (i.e., it's time to shoot)
func _on_timer_timeout():
	if shooting:  # Only shoot if we are still actively shooting
		shoot()

# Called every frame in the physics process
func _physics_process(_delta):
	var enemies_in_range = get_overlapping_bodies()
	if enemies_in_range.size() > 0:
		var target_player = Global.player
		look_at(target_player.global_position)
		if not shooting:
			shooting = true
			timer.start(rate_of_fire)
	else:
		# No enemies in range, stop shooting
		if shooting:
			shooting = false
			timer.stop()  # Stop the shooting timer when no enemies are detected

# Function to handle shooting
func shoot():
	const BULLET = preload("res://Scenes/TankBullet.tscn")
	var new_bullet = BULLET.instantiate()
	
	new_bullet.global_position = shootingpoint.global_position
	
	var target_player = Global.player
	if target_player:
		var direction = (target_player.global_position - shootingpoint.global_position).normalized()
	
		new_bullet.rotation = direction.angle()
	
		new_bullet.set_direction(direction)
	
	get_tree().current_scene.add_child(new_bullet)
	audio_stream_player_2d.play()

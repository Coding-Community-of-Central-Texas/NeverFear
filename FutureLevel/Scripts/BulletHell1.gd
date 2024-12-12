extends Node2D

@export var bullet_scene = preload("res://Scenes/BossBullet.tscn")  # The bullet scene
@export var bullet_speed = 350  # Speed of the bullets
@export var bullet_count = 9  # Number of bullets per wave
@export var angle_spread = 45  # Angle spread for the fan bullet pattern
@onready var timer: Timer = $Timer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var stream_direction = 5  # 1 for up, -1 for down

func _ready():
	timer.start()

func _on_timer_timeout() -> void:
	audio_stream_player_2d.play()
	var pattern_choice = randi() % 3  # Choose a pattern (0, 1, or 2)
	match pattern_choice:
		0:
			fan_pattern()
		1:
			circle_pattern()
		2:
			stream_pattern()


func fan_pattern():
	# Generate a fan of bullets
	for i in range(bullet_count):
		var angle = deg_to_rad(i * (angle_spread / (bullet_count - 1)) - angle_spread / 2)
		var direction = Vector2(cos(angle), sin(angle))
		spawn_bullet(global_position, -direction * bullet_speed)

func circle_pattern():
	var bullet_count = 20
	# Generate a circular spread of bullets
	for i in range(bullet_count):
		var angle = deg_to_rad(i * (360 / bullet_count))
		var direction = Vector2(cos(angle), sin(angle))
		spawn_bullet(global_position, direction * bullet_speed)

func stream_pattern():
	var bullet_count = 3
	# Generate a stream of bullets that oscillates up and down
	for i in range(bullet_count):
		var offset = i * 30 * stream_direction  # Offset for the wave effect
		var bullet_position = global_position + Vector2(0, offset)
		spawn_bullet(bullet_position, Vector2(-bullet_speed, 0))  # Stream moves horizontally
	stream_direction *= -1  # Reverse direction for the next wave



func spawn_bullet(position: Vector2, velocity: Vector2):
	# Spawn and configure a bullet
	var bullet = bullet_scene.instantiate()
	bullet.position = position
	bullet.velocity = velocity
	get_tree().current_scene.add_child(bullet)

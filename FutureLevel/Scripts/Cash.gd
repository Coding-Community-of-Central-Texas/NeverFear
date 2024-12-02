extends Area2D

const GRAVITY = 180
const MAX_FALL_SPEED = 250.0# Maximum falling speed


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var ground_ray_cast_2d: RayCast2D = $GroundRayCast2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


var pickup_song: AudioStream = preload("res://assets/FutrueSFX/PickUp.wav")
var velocity = Vector2.ZERO

enum PowerUpType {
	SPEED, 
	HEALTH, 
	FIRE_RATE
}

var power_up_type: PowerUpType
var power_up_value: float 


func _on_ready(): 
	animated_sprite_2d.play("spin")
	ground_ray_cast_2d.enabled = true
	audio_stream_player_2d.stream = pickup_song
	randomize_power_up()

func randomize_power_up():
	#var power_up_count = PowerUpType.FIRE_RATE + 1
	
	power_up_type = randi()
	# Randomize power-up value based on type
	match power_up_type:
		PowerUpType.SPEED:
			power_up_value = randi_range(30, 60)  # Random speed boost
		PowerUpType.HEALTH:
			power_up_value = randi_range(10, 25)  # Random health boost
		PowerUpType.FIRE_RATE:
			power_up_value = randi_range(1, 5) / 100.0  # Random fire rate reduction
	print("Randomized power-up type:", power_up_type)
	print("Power-up value:", power_up_value)

func _physics_process(delta: float):
	# Apply gravity if not on the floor
	if !ground_ray_cast_2d.is_colliding():
		velocity.y += GRAVITY * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)  # Cap the falling speed
		position += velocity * delta
	else:
		velocity.y = 0  # Stop falling when the ray detects the ground


func _on_body_entered(body):
	if body.is_in_group("player"):
		if audio_stream_player_2d.stream != null:
			audio_stream_player_2d.play()
		visible = false
		apply_power_up()

func apply_power_up():
	var original_speed = Global.player.SPEED
	var original_health = Global.player.health
	var original_fire_rate = Global.player.rate_of_fire
	
	match power_up_type:
		PowerUpType.SPEED:
			Global.player.SPEED += power_up_value
		PowerUpType.HEALTH:
			Global.player.health = min(Global.player.MAX_HEALTH, Global.player.health + power_up_value)
		PowerUpType.FIRE_RATE:
			Global.player.rate_of_fire = max(0.1, Global.player.rate_of_fire - power_up_value)
	
	check_if_stats_boosted(original_speed, original_health, original_fire_rate)

func check_if_stats_boosted(original_speed, original_health, original_fire_rate):
	if power_up_type == PowerUpType.SPEED and Global.player.SPEED > original_speed:
		print("Speed boosted!")
	elif power_up_type == PowerUpType.HEALTH and Global.player.health > original_health:
		print("Health boosted!")
	elif power_up_type == PowerUpType.FIRE_RATE and Global.player.rate_of_fire < original_fire_rate:
		print("Fire rate boosted!")

func _on_audio_stream_player_2d_finished() -> void:
	queue_free()

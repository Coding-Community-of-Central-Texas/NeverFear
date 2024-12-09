extends Area2D

signal add_cash

var GRAVITY = 180
var MAX_FALL_SPEED = 250.0# Maximum falling speed


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var ground_ray_cast_2d: RayCast2D = $GroundRayCast2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


var pickup_song: AudioStream = preload("res://assets/FutrueSFX/PickUp.wav")
var velocity = Vector2.ZERO

enum PowerUpType {
	SPEED, 
	HEALTH, 
	LIVES
}

var power_up_type: PowerUpType
var power_up_value: float 


func _on_ready(): 
	animated_sprite_2d.play("spin")
	ground_ray_cast_2d.enabled = true
	audio_stream_player_2d.stream = pickup_song
	
	if get_tree().current_scene.name == "HypercoreGauntlet":
		GRAVITY = 0  # Disable gravity in this scene
		MAX_FALL_SPEED = 0
		ground_ray_cast_2d.enabled = false
	else: 
		return

	randomize_power_up()

func randomize_power_up():
	# Define weighted probabilities for each power-up type
	var weights = {
		PowerUpType.SPEED: 50,  # 50% chance
		PowerUpType.HEALTH: 40,  # 40% chance
		PowerUpType.LIVES: 10   # 10% chance
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
		PowerUpType.SPEED:
			power_up_value = randi_range(15, 19)  # Random speed boost
		PowerUpType.HEALTH:
			power_up_value = randi_range(5, 10)   # Random health boost
		PowerUpType.LIVES:
			power_up_value = randi_range(0, 1)   # Random life amount

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
		emit_signal("add_cash")
		apply_power_up()

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
	
	check_if_stats_boosted(original_speed, original_health, original_lives)

func check_if_stats_boosted(original_speed, original_health, original_lives):
	if power_up_type == PowerUpType.SPEED and Global.player.SPEED > original_speed:
		print("Speed boosted!")
	elif power_up_type == PowerUpType.HEALTH and Global.player.health > original_health:
		print("Health boosted!")
	elif power_up_type == PowerUpType.LIVES and Global.lives < original_lives:
		print("Fire rate boosted!")

func _on_audio_stream_player_2d_finished() -> void:
	queue_free()


func _on_add_cash() -> void:
	GameManager._on_add_cash(randi_range(1000, 10000))
	

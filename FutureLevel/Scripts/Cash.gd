extends Area2D

signal add_cash

var GRAVITY = 200
var MAX_FALL_SPEED = 250.0# Maximum falling speed



@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var ground_ray_cast_2d: RayCast2D = $GroundRayCast2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var pickup_song: AudioStream = preload("res://assets/FutrueSFX/PickUp.wav")
var velocity = Vector2.ZERO

enum PowerUpType {
	CASH,
	SPEED, 
	HEALTH, 
	LIVES
}

var power_up_type: PowerUpType
var power_up_value: float 


func _on_ready(): 
	%CashSpin.play("spin")
	ground_ray_cast_2d.enabled = true
	audio_stream_player_2d.stream = pickup_song
	animation_player.play("moveUpnDown")
	
	randomize_power_up()

func randomize_power_up():
	# Define weighted probabilities for each power-up type
	var weights = {
		PowerUpType.CASH: 69,
		PowerUpType.SPEED: 10,  
		PowerUpType.HEALTH: 16,  
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
			%CashSpin.visible = true
			%Star.visible = false
			%Health.visible = false
			%Heart.visible = false
		PowerUpType.SPEED:
			power_up_value = randi_range(15, 40)
			%Star.visible = true
			%Health.visible = false
			%Heart.visible = false
			%CashSpin.visible = false
		PowerUpType.HEALTH:
			power_up_value = randi_range(10, 60)  
			%Health.visible = true
			%Star.visible = false
			%Heart.visible = false
			%CashSpin.visible = false
		PowerUpType.LIVES:
			power_up_value = randi_range(0, 1)   
			%Heart.visible = true 
			%Star.visible = false
			%Health.visible = false
			%CashSpin.visible = false

	print("Randomized power-up type:", power_up_type)
	print("Power-up value:", power_up_value)


func _physics_process(delta: float):
	if get_tree().current_scene.is_in_group("Legacy"):
		if !ground_ray_cast_2d.is_colliding():
			velocity.y += GRAVITY * delta
			velocity.y = min(velocity.y, MAX_FALL_SPEED)  # Cap the falling speed
			position += velocity * delta
		else:
			velocity.y = 0  # Stop falling when the ray detects the ground
	else:
		pass

func _on_body_entered(body):
	if body.is_in_group("player"):
		if audio_stream_player_2d.stream != null:
			audio_stream_player_2d.play()
		visible = false
		if power_up_type == PowerUpType.CASH:
			emit_signal("add_cash")  
		else:
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
		print("Speed up")
	elif power_up_type == PowerUpType.HEALTH and Global.player.health > original_health:
		print("healthUp")
	elif power_up_type == PowerUpType.LIVES and Global.lives < original_lives:
		print("livesup")

func _on_audio_stream_player_2d_finished() -> void:
	queue_free()


func _on_add_cash() -> void:
	GameManager.add_cash(randi_range(1000, 10000))
	print("add cash")
	


func _on_queue_timer_timeout() -> void:
	queue_free()

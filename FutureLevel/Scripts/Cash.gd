extends Area2D

const GRAVITY = 200
const MAX_FALL_SPEED = 300.0# Maximum falling speed


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var ground_ray_cast_2d: RayCast2D = $GroundRayCast2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


var pickup_song: AudioStream = preload("res://assets/FutrueSFX/PickUp.wav")
var velocity = Vector2.ZERO

func _on_ready(): 
	animated_sprite_2d.play("spin")
	ground_ray_cast_2d.enabled = true
	audio_stream_player_2d.stream = pickup_song

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
		print("+$10,000")
		if audio_stream_player_2d.stream != null:
			audio_stream_player_2d.play()
	visible = false

func _on_audio_stream_player_2d_finished() -> void:
	queue_free()

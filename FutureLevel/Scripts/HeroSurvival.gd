extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

var health = 100
var direction : Vector2 = Vector2(0,0)
const SPEED = 500
var is_dead = false 

func _physics_process(delta):
	if direction:
		velocity.x = direction.x * SPEED
		velocity.y = direction.y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	move_and_slide()

func _die():
	if is_dead:
		return
	is_dead = true
	animated_sprite_2d.play("death")
	


func handle_player_animation() -> void:
		if is_dead:
			if animated_sprite_2d.animation != "death" or not animated_sprite_2d.is_playing():
				animated_sprite_2d.play("death")
				return

		if direction.length() > 0:
		# Determine the direction of movement
			if abs(direction.x) > abs(direction.y):  # Horizontal movement
				if direction.x > 0:
					animated_sprite_2d.play("move_right")  # Animation for moving right
			else:
				animated_sprite_2d.play("move_left")  # Animation for moving left
			else:  # Vertical movement
				if direction.y > 0:
					animated_sprite_2d.play("move_down")  # Animation for moving down
			else:
				animated_sprite_2d.play("move_up")  # Animation for moving up
			else:
				animated_sprite_2d.play("idle")  # Idle animation for no movement


func _on_joystick_joystick_input(strength, dir, delta) -> void:
		direction = dir

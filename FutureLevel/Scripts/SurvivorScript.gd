
extends CharacterBody2D

# Player properties
var health: float = 100.0
const MAX_HEALTH: float = 100.0
var SPEED: float = 300.0
var direction: Vector2 = Vector2.ZERO

# Animation setup
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var joystick: Node = $Joystick

func _ready() -> void:
	# Initialize the player's properties
	health = MAX_HEALTH
	# Connect joystick signals

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_player_animation()
	move_and_slide()

# Handle joystick input to update direct

# Handle movement based on joystick input
func handle_movement(delta: float) -> void:
	velocity = direction * SPEED

# Handle animations based on movement direction
func handle_player_animation() -> void:
	if direction == Vector2.ZERO:
		animated_sprite_2d.play("idle")
	else:
		if abs(direction.x) > abs(direction.y):  # Horizontal movement
			if direction.x > 0:
				animated_sprite_2d.play("run")
			else:
				animated_sprite_2d.play("run")
		else:  # Vertical movement
			
			if direction.y > 0:
				animated_sprite_2d.play("run")
			else:
				animated_sprite_2d.play("run")


func _on_joystick_joystick_input(strength, dir, delta) -> void:
	direction = dir * strength
	



func _on_joystick_joystick_released() -> void:
	direction = Vector2.ZERO

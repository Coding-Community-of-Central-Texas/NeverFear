
extends CharacterBody2D

# Player properties
var health: float = 100.0
const MAX_HEALTH: float = 100.0
var SPEED: float = 200.0
var direction: Vector2 = Vector2.ZERO

# Animation and joystick setup
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var joystick: Node = $Joystick

func _ready() -> void:
    # Initialize the player's properties
    health = MAX_HEALTH

func _physics_process(delta: float) -> void:
    handle_movement(delta)
    handle_player_animation()

    move_and_slide()

# Handle movement based on joystick input
func handle_movement(delta: float) -> void:
    # Reset direction
    direction = Vector2.ZERO

    # Get joystick input
    if joystick.has_method("get_direction"):
        direction = joystick.get_direction()

    # Normalize direction and update velocity
    if direction.length() > 1:
        direction = direction.normalized()

    velocity = direction * SPEED

# Handle animations based on movement direction
func handle_player_animation() -> void:
    if direction == Vector2.ZERO:
        animated_sprite_2d.play("idle")
    else:
        if abs(direction.x) > abs(direction.y):  # Horizontal movement
            if direction.x > 0:
                animated_sprite_2d.play("move_right")
            else:
                animated_sprite_2d.play("move_left")
        else:  # Vertical movement
            if direction.y > 0:
                animated_sprite_2d.play("move_down")
            else:
                animated_sprite_2d.play("move_up")

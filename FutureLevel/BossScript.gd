extends CharacterBody2D

var boss_health: float = 10000.0

@export var SPEED: float = 200.0
@export var AUTOMATIC_MOVEMENT: bool = true
@export var AUTO_DIRECTION: int = 1 # 1 for right, -1 for left
@onready var health_bar: ProgressBar = $HealthBar
@onready var right_wall: RayCast2D = $RightWall
@onready var left_wall: RayCast2D = $LeftWall
@onready var left_ground: RayCast2D = $LeftGround
@onready var right_ground: RayCast2D = $RightGround


func _ready() -> void:
	%Robo.play_attack()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if AUTOMATIC_MOVEMENT:
		# Automatic movement logic
		velocity.x = AUTO_DIRECTION * SPEED

		# Reverse direction if hitting a wall
		if is_on_wall():
			AUTO_DIRECTION *= -1
		
		if is_near_wall():
			AUTO_DIRECTION = -AUTO_DIRECTION
	move_and_slide()

func is_near_wall() -> bool:
	if AUTO_DIRECTION == 1:
		return right_wall.is_colliding()
	elif AUTO_DIRECTION == -1:
		return left_wall.is_colliding()
	return false 


func take_damage():
	boss_health -= 100
	%Robo.play_hurt()
	health_bar.value = boss_health
	if boss_health <= 0:
		die()

func die():
	%Robo.play_hurt()
	queue_free()


func _on_boss_robo_hurt() -> void:
	take_damage()

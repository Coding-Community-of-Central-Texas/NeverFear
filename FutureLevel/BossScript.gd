extends CharacterBody2D

var boss_health: float = 10000.0

@export var SPEED: float = 100.0
@export var AUTOMATIC_MOVEMENT: bool = true
@export var AUTO_DIRECTION: int = 1 # 1 for right, -1 for left
@onready var health_bar: ProgressBar = $HealthBar
@onready var right_wall: RayCast2D = $RightWall
@onready var left_wall: RayCast2D = $LeftWall
@onready var left_ground: RayCast2D = $LeftGround
@onready var right_ground: RayCast2D = $RightGround
@onready var start_attack: Timer = $StartAttack
@onready var fire: Timer = $Fire
@onready var fireloop: Timer = $Fireloop
@onready var basic_gun: Area2D = $BasicGun
@onready var basic_gun_2: Area2D = $BasicGun2


func _ready() -> void:
	%Robo.play_walk()
	start_attack.start()

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
	return

func attack():
	AUTOMATIC_MOVEMENT = false
	%Robo.play_attack()
	fire.start()

func die():
	%Robo.play_die()
	const TROPHY = preload("res://Scenes/End.tscn")
	var new_trophy = TROPHY
	new_trophy.position = global_position
	add_child(new_trophy)
	call_deferred("queue_free")

func _on_start_attack_timeout() -> void:
	attack()
	start_attack.stop()

func _on_fire_timeout() -> void:
	start_attack.stop()
	basic_gun.collision_mask = 3; basic_gun_2.collision_mask = 3;
	fireloop.start()


func _on_fireloop_timeout() -> void:
	fireloop.stop()
	basic_gun.collision_mask = 0; basic_gun_2.collision_mask = 0; 
	_ready()

extends CharacterBody2D

var boss_health: float = 10000.0
var die_executed: bool = false
@onready var health_bar: ProgressBar = $HealthBar
@onready var right_wall_ray: RayCast2D = $RightWall
@onready var left_wall_ray: RayCast2D = $LeftWall
@onready var left_ground: RayCast2D = $LeftGround
@onready var right_ground: RayCast2D = $RightGround
@onready var start_attack: Timer = $StartAttack
@onready var attack_duration: Timer = $AttackDuration
@onready var die_timer: Timer = $Die
@onready var fire_point: Marker2D = $FirePoint

var is_attacking = false
var move_speed = 100.0  # Movement speed
var max_distance = 150.0  # The max distance to move before reversing direction
var direction = 1  # 1 for right, -1 for left
var starting_position = Vector2.ZERO

func _ready():
	%Robo.play_walk()
	start_attack.start()
	direction = 1 
	back_and_forth_movement()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	back_and_forth_movement()
	move_and_slide()

func back_and_forth_movement():
	velocity.x = direction * move_speed

	if is_near_wall():
		direction = -direction

func is_near_wall() -> bool:
	if direction == 1:
		return right_wall_ray.is_colliding()
	elif direction == -1:
		return left_wall_ray.is_colliding()
	return false 



func take_damage():
	boss_health -= 100
	%Robo.play_hurt()
	health_bar.value = boss_health
	if boss_health <= 0 and not die_executed:
		die()
	return

@onready var bullet_hell_scene = preload("res://Scenes/BulletHell1.tscn")

func attack():
	is_attacking = true
	%Robo.play_attack()
	bullets()
	direction = 0
	attack_duration.start()

func die():
	direction = 0
	die_executed = true 
	%BigBoom.boss_bang()
	%Robo.visible = false
	die_timer.start()


func bullets():
	var bullet_hell_instance = bullet_hell_scene.instantiate()
	bullet_hell_instance.position = fire_point.global_position  # You can adjust the position if needed
	get_tree().current_scene.add_child(bullet_hell_instance)

func _on_start_attack_timeout() -> void:
	attack()
	
	
func _on_attack_duration_timeout() -> void:
	is_attacking = false
	direction = 1  # Resume movement
	start_attack.start()  # Restart the attack sequence



func _on_die_timeout() -> void:
	const TROPHY = preload("res://Scenes/End.tscn")
	var new_trophy = TROPHY.instantiate()
	new_trophy.position = global_position
	get_tree().current_scene.call_deferred("add_child", new_trophy)
	queue_free()

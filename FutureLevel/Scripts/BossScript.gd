extends CharacterBody2D

var boss_health: float = 10000.0
var die_executed: bool = false

@onready var health_bar: ProgressBar = %HealthBar
@onready var right_wall_ray: RayCast2D = $RightWall
@onready var left_wall_ray: RayCast2D = $LeftWall
@onready var start_attack: Timer = $StartAttack
@onready var attack_duration: Timer = $AttackDuration
@onready var die_timer: Timer = $DieTimer
@onready var shooting_point: Marker2D = $ShootingPoint


@onready var bullet_hell_scene = preload("res://Scenes/BulletHell1.tscn")

var move_speed = 100.0  # Movement speed
var direction = 1  # 1 for right, -1 for left
var is_attacking = false  # Whether the boss is currently attacking

func _ready():
	%Robo.play_walk()
	start_attack.start()  # Start the attack sequence

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if not is_attacking:
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
	self.modulate = Color(1, 0, 0)  # Set to red
	await get_tree().create_timer(0.1).timeout  # Wait for 0.1 seconds
	self.modulate = Color(1, 1, 1)  # Reset to normal
	%HealthBar.value = boss_health
	if boss_health <= 0 and not die_executed:
		die()

func attack():
	is_attacking = true
	direction = 0  # Stop movement
	%Robo.play_attack()
	bullets()
	attack_duration.start()  # Timer to end the attack phase

func die():
	die_executed = true 
	direction = 0
	is_attacking = true
	%BigBoom.boss_bang()
	%Robo.visible = false
	die_timer.start()

func bullets():
	var bullet_hell_instance = bullet_hell_scene.instantiate()
	bullet_hell_instance.position = shooting_point.global_position
	get_tree().current_scene.add_child(bullet_hell_instance)

# Timer Callbacks
func _on_start_attack_timeout() -> void:
	attack()

func _on_attack_duration_timeout() -> void:
	is_attacking = false
	direction = 1  # Resume movement
	start_attack.start()  # Restart the attack sequence



func _on_die_timer_timeout() -> void:
	const TROPHY = preload("res://Scenes/End.tscn")
	var new_trophy = TROPHY.instantiate()
	new_trophy.position = global_position
	get_tree().current_scene.call_deferred("add_child", new_trophy)
	queue_free()

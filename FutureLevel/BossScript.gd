extends CharacterBody2D

var boss_health: int = 300

@export var SPEED: float = 200.0
@export var AUTOMATIC_MOVEMENT: bool = true
@export var AUTO_DIRECTION: int = 1 # 1 for right, -1 for left
@onready var health_bar: ProgressBar = %HealthBar

func _ready() -> void:
	%BossRobo.play_attack()

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
	move_and_slide()

func take_damage():
	boss_health -= 100
	%BossRobo.play("hurt")
	health_bar.boss_health = boss_health
	if boss_health <= 0:
		die()

func die():
	Engine.time_scale = 0.5
	queue_free()
	get_tree().change_scene_to_file("res://Scenes/WinScreen.tscn")

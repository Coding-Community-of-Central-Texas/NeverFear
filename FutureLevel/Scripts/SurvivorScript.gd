# file: scripts/player.gd
extends CharacterBody2D

signal rank_changed(rank_index: int)
signal playerdeath

# Player properties
var health: float = 500.0
const MAX_HEALTH = 500
const VELOCITY = 1000
@export var SPEED: float = 500.0
@export var acceleration: float = 2200
@export var deceleration: float = 4000
const DEADZONE: float = 0.15  # small pad for sticks/float rounding
@onready var shadow: Sprite2D = $AnimatedSprite2D/Shadow
@onready var rank_1: Sprite2D = $Rank1
@onready var rank_2: Sprite2D = $Rank2
@onready var rank_3: Sprite2D = $Rank3
@onready var rank_4: Sprite2D = $Rank4
@onready var rank_5: Sprite2D = $Rank5
@onready var gun: Area2D = $Gun

# Animation setup
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = %HealthBar
@onready var timer_2: Timer = $Timer2
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var is_dead: bool = false
var current_kills: int = 0
@export var rank_thresholds: Array = [50, 300, 400, 500, 600]
@export var fire_rates: Array = [0.20, 0.15, 0.10, 0.08, 0.05]

func _ready() -> void:
	Global.player = self
	GameManager.connect("scene_kill_updated", Callable(self, "_on_game_manager_scene_kill_updated"))

func take_damage(amount: int):
	if is_dead:
		return
	health -= amount
	health_bar.value = health
	await get_tree().create_timer(0.2).timeout
	health_bar.indeterminate = true
	animated_sprite_2d.self_modulate = Color(10, 0, 0)
	await get_tree().create_timer(0.2).timeout
	animated_sprite_2d.self_modulate = Color(1, 1, 1)
	health_bar.indeterminate = false 
	if health <= 0:
		_die()

func _die():
	if is_dead:
		return
	is_dead = true
	emit_signal("playerdeath")
	animated_sprite_2d.play("death")
	timer_2.start()
	audio_stream_player.play()
	
func update_shooting_rate():
	if gun.has_method("stop_shooting"):
		gun.call("stop_shooting")
	if gun.has_method("_physics_process(_delta: float)"):
		gun.call("_physics_process(_delta: float)")

func rank_up():
	for i in range(rank_thresholds.size()):
		if current_kills < rank_thresholds[i]:
			_update_rank_display(i)
			emit_signal("rank_changed", i)
			return
	_update_rank_display(rank_thresholds.size())
	emit_signal("rank_changed", rank_thresholds.size())

func _update_rank_display(rank_index: int) -> void:
	if rank_index >= fire_rates.size():
		rank_index = fire_rates.size() - 1
	gun.rate_of_fire = fire_rates[rank_index]
	update_shooting_rate()
	rank_1.visible = rank_index == 0
	rank_2.visible = rank_index == 1
	rank_3.visible = rank_index == 2
	rank_4.visible = rank_index == 3
	rank_5.visible = rank_index == 4

func _physics_process(delta: float) -> void:
	# Input as a vector; works for keyboard & sticks
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	var has_input := input_dir.length() > DEADZONE

	var target_velocity := Vector2.ZERO
	if has_input:
		target_velocity = input_dir.normalized() * SPEED
		# accelerate toward desired velocity
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		# use stronger braking when no input to avoid "ice" feel
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		if velocity.length() < 5.0:
			velocity = Vector2.ZERO  # snap tiny residuals

	move_and_slide()
	flip_sprite()
	handle_collisions(delta)
	handle_player_animation()

func handle_collisions(delta: float):
	const DAMAGE_RATE = 10.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	health_bar.value = health
	
	if overlapping_mobs.size() > 0:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		health_bar.value = health
	if health <= 0:
		_die()

func handle_player_animation() -> void:
	if velocity.length() > 0:
		if animation_player.current_animation != "walk":
			animation_player.play("walk")
	else:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")

func flip_sprite() -> void:
	if velocity.x < -3:
		animated_sprite_2d.flip_h = true
		gun.position = Vector2(4, 3)
		shadow.position = Vector2(5, 34)
		%SuperSayain.position = Vector2(19.6, 36.8)
		%SuperSayain4.position = Vector2(19.2, 33.7)
	elif velocity.x > 3:
		gun.position = Vector2(-4, 3)
		animated_sprite_2d.flip_h = false
		shadow.position = Vector2(-9.5, 34)
		%SuperSayain.position = Vector2(-5.0, 32.6)
		%SuperSayain4.position = Vector2(-3.8, 28.8)

func _on_timer_2_timeout() -> void:
	_game_over()
	GameManager.reset_scene_kills()

func _game_over():
	const GAMEOVER = preload("res://Scenes/GameOver.tscn")
	var new_gameover = GAMEOVER.instantiate()
	add_child(new_gameover)

func _on_spawn_timer_timeout() -> void:
	const SPAWN = preload("res://Scenes/SpawnCircle.tscn")
	const BIGSPAWN = preload("res://Scenes/BigSpawnCircle.tscn")
	var new_big = BIGSPAWN.instantiate()
	var new_spawn = SPAWN.instantiate()
	new_big.position = global_position
	new_spawn.position = global_position
	add_child(new_big)
	add_child(new_spawn)

func _on_game_manager_scene_kill_updated(kills: int) -> void:
	current_kills = kills
	rank_up()

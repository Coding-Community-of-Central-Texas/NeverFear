extends Area2D

var travelled_distance = 0.0
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
var velocity = Vector2.ZERO
@onready var explosion: AnimatedSprite2D = %Explosion
@onready var missile: Sprite2D = $Missile

# Homing missile variables
var homing_duration = 3.0 # seconds to track the player
var homing_timer = 0.0
var is_homing = true
var missile_speed = 200.0

func _ready():
	%AnimatedSprite2D.play("shoot")
	%AnimatedSprite2D.flip_h
	homing_timer = homing_duration

func _physics_process(delta):
	const RANGE = 678.0
	if is_homing and Global.player:
		# Home in on the player
		var to_player = (Global.player.global_position - global_position).normalized()
		velocity = to_player * missile_speed
		homing_timer -= delta
		if homing_timer <= 0.0:
			is_homing = false
			missile_impact()
	else:
		# Continue in last direction if not homing
		pass

	var displacement = velocity * delta
	position += displacement
	
	# Point the missile in the direction of movement
	if velocity.length() > 0:
		rotation = velocity.angle()

	travelled_distance += displacement.length()
	if travelled_distance > RANGE:
		missile_impact()

func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		missile_impact()
		body.take_damage(25)

func missile_impact():
	missile.visible = false
	%Explosion.visible = true
	%Explosion.play("missile_impact")
	await get_tree().create_timer(0.8).timeout
	queue_free()

func set_direction(direction: Vector2):
	velocity = direction.normalized() * missile_speed

extends Area2D

var travelled_distance = 0.0
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var velocity = Vector2.ZERO

func _ready():
	animated_sprite_2d.play("shoot")

func _physics_process(delta):
	const RANGE = 678.0
	
	var displacement = velocity * delta
	position += displacement
	
	travelled_distance += displacement.length()
	if travelled_distance > RANGE:
		queue_free()
		
func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()
	queue_free()

func set_direction(direction: Vector2):
	velocity = direction.normalized() * 160

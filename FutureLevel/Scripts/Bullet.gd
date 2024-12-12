extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

var travelled_distance = 0.0



func _physics_process(delta):
	const SPEED = 2000.0
	const RANGE = 300.0
	
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * SPEED * delta
	
	travelled_distance += SPEED * delta
	if travelled_distance > RANGE:
		queue_free()

func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage()
		%AnimatedSprite2D.visible = true
	queue_free()

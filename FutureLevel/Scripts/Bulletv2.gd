extends Area2D

var travelled_distance = 0.0



func _ready():
	connect("body_entered", Callable(self,"_on_body_entered"))

func _physics_process(delta):
	const SPEED = 2000.0
	const RANGE = 578.0
	
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * SPEED * delta
	
	travelled_distance += SPEED * delta
	if travelled_distance > RANGE:
		queue_free()

func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage()
	visible = false

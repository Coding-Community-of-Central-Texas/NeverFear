extends Area2D

@export var speed = 400  # Speed of the bullet
@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var collision_shape = $CollisionShape2D
var velocity = Vector2(0, -speed)

func _ready():
	sprite_2d.play("lava")

func _process(delta):
	position += velocity * delta

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(20)
	queue_free()

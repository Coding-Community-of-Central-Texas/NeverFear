extends Area2D

@export var conveyor_speed: float = 25.0  # Speed of movement
var players_on_belt = []
var direction = Vector2()

func _ready():
	randomize_direction()

func randomize_direction():
	var angle = randf() * PI * 2  # Random angle in radians
	direction = Vector2(cos(angle), sin(angle)).normalized()

func _process(delta):
	for player in players_on_belt:
		if player:  # Ensure the player reference is valid
			player.velocity = direction * conveyor_speed  # Apply consistent force
			player.move_and_slide()  # Move the player

func _on_body_entered(body):
	if body is CharacterBody2D:
		players_on_belt.append(body)

func _on_body_exited(body):
	if body is CharacterBody2D:
		players_on_belt.erase(body)

extends Area2D

@export var conveyor_speed: float = 5.0  # Speed of movement
var players_on_belt = []

func _process(_delta):
	for player in players_on_belt:
		if player and player is CharacterBody2D:  # Ensure the player is valid
			player.velocity.x += conveyor_speed  # Apply movement in the X direction
			player.move_and_slide()  # Move the player

func _on_body_entered(body):
	if body is CharacterBody2D:
		players_on_belt.append(body)

func _on_body_exited(body):
	if body is CharacterBody2D:
		players_on_belt.erase(body)

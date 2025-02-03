extends Area2D

@export var conveyor_speed: int = 50.0  # Speed of movement
var players_on_belt = []


func _process(delta):
	for player in players_on_belt:
		if player:  # Ensure the player reference is valid
			player.velocity = conveyor_speed + player.speed  # Apply consistent force
			player.move_and_slide()  # Move the player

func _on_body_entered(body):
	if body is CharacterBody2D:
		players_on_belt.append(body)

func _on_body_exited(body):
	if body is CharacterBody2D:
		players_on_belt.erase(body)

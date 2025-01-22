extends Area2D

@onready var gauntlet_door: AnimatedSprite2D = $GauntletDoor

func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):
		gauntlet_door.play("open")

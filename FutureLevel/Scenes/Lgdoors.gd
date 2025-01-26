extends Area2D

@onready var legacy_door: AnimatedSprite2D = $LegacyDoor



func _on_body_entered(body):
	if body.is_in_group("player"):
		legacy_door.play("open")

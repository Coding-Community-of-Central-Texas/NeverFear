extends Area2D


@onready var stat_door: AnimatedSprite2D = $StatDoor



func _on_body_entered(body):
	if body.is_in_group("player"):
		stat_door.play("open")

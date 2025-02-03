extends Area2D

@onready var gauntlet_door: AnimatedSprite2D = $GauntletDoor


func _on_body_entered(body):
	if body.is_in_group("player"):
		gauntlet_door.play("open")

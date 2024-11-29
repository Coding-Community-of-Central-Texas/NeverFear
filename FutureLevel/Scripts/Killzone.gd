extends Area2D

@onready var timer: Timer = $Timer


func _on_body_entered(body):
	Engine.time_scale = 0.5
	if body.is_in_group("player"):
		body._die()
	timer.start()
	print("you Died")

	
	
	
func _on_timer_timeout():
	Engine.time_scale = 1.0

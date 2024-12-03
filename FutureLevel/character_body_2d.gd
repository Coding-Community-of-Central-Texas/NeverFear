extends CharacterBody2D


var speed := 200
var velocity := -400


func process(_delta: float) -> void:
	velocity.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	velocity = velocity.normalized()
	
func _physics_process(delta: float) -> void:
	move_and_slide(velocity * speed)

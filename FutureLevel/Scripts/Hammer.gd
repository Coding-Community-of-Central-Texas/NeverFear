extends Node2D

@onready var hammer_pys: AnimatableBody2D = $HammerPys
@onready var animation_player: AnimationPlayer = $AnimationPlayer

enum hamer_time {
	HAMMER1,
	HAMMER2,
	HAMMER3,
}

func _ready() -> void:
	_randomize_animation()

func _randomize_animation() -> void:
	var animations = animation_player.get_animation_list()
	var random_animation = animations[randi() % animations.size()]
	animation_player.play(random_animation)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()# Replace with function body.

extends Area2D

@onready var scene_transition: AnimationPlayer = $"../SceneTransitionScreen/SceneTransition"

func _on_body_entered(body):
	if body.is_in_group("player"):
		scene_transition.play("Transition")
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://Scenes/HypercoreGauntlet.tscn")

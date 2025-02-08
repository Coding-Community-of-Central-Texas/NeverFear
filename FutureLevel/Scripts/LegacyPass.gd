extends Area2D

@onready var scene_transition: AnimationPlayer = $"../SceneTransitionScreen/SceneTransition"
@onready var lightrays_8: Sprite2D = $Lightrays8



func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):
		lightrays_8.visible = true
		scene_transition.play("Transition")
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://Scenes/LegacyProtocol.tscn")

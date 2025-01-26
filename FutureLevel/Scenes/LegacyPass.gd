extends Area2D

@onready var door: AnimatedSprite2D = $Door
@onready var scene_transition: AnimationPlayer = $"../SceneTransition"


func _on_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("player"):
		scene_transition.play("Transition")
		await get_tree().create_timer(0.9).timeout
		get_tree().change_scene_to_file("res://Scenes/LegacyProtocol.tscn")

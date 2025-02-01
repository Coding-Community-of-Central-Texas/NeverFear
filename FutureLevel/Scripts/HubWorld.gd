extends Node2D

@onready var scene_transition: AnimationPlayer = $SceneTransitionScreen/SceneTransition


func _ready() -> void:
	Engine.time_scale = 1.0
	scene_transition.play("Enter")

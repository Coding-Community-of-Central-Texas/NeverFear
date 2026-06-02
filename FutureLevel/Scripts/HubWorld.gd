extends Node2D

@onready var scene_transition: AnimationPlayer = $SceneTransitionScreen/SceneTransition

func _ready() -> void:
	Engine.time_scale = 1.0
	if scene_transition.has_animation("Enter"):
		scene_transition.play("Enter")
	Ads.prepare_game_over_ad()

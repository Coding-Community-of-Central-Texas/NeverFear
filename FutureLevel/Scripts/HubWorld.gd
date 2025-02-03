extends Node2D

@onready var scene_transition: AnimationPlayer = $SceneTransitionScreen/SceneTransition
const HERO = preload("res://Scenes/Hero.tscn")
@onready var marker_2d: Marker2D = $Marker2D


func _ready() -> void:
	Engine.time_scale = 1.0
	scene_transition.play("Enter")

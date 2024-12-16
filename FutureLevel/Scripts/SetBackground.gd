extends Area2D

@onready var pipland: Sprite2D = $"../TileMap/CityBack/Background/Pipland"

func _ready() -> void:
	pipland.visible = false

func _on_body_entered(body: Node2D) -> void:
	pipland.visible = true

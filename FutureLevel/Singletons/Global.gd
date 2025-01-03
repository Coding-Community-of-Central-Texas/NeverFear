extends Node

var player = ["res://Scenes/Hero.tscn", "res://Scenes/Survivor.tscn"]
var legacy = "res://Scenes/LegacyProtocol.tscn"
var gauntlet = "res://Scenes/HypercoreGauntlet.tscn"
var lives: int = 3  
var checkpoint_position: Vector2 = Vector2(353.993, -306.008)


 
func reset_game_state():
	checkpoint_position = Vector2(353.993, -306.008) # Starting position
	lives = 3  # Reset lives to the initial value
	Engine.time_scale = 1.0
	GameManager.reset_scene_kills()

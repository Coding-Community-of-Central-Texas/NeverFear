extends Node

var player = ["res://Scenes/Hero.tscn", "res://Scenes/Survivor.tscn"]
var legacy = "res://Scenes/LegacyProtocol.tscn"
var gauntlet = "res://Scenes/HypercoreGauntlet.tscn"
var hub = "res://Scenes/HubWorld.tscn"
var lives: int = 3  
var checkpoint_position: Vector2 = Vector2(353.993, -306.008)
var hub_world_position: Vector2 = Vector2(144.501, -387.5)
var returning_from_game: bool = false  # Flag to track return state

# Call this function when entering the Hub World
func enter_hub_world():
	returning_from_game = true
	if get_tree().current_scene.is_in_group("Hub"):
		checkpoint_position = Vector2(144.501, -387.5)
	else:
		checkpoint_position = Vector2(353.993, -306.008)
 
func reset_game_state():
	checkpoint_position = Vector2(353.993, -306.008) # Starting position
	lives = 3  # Reset lives to the initial value
	Engine.time_scale = 1.0
	GameManager.reset_scene_kills()

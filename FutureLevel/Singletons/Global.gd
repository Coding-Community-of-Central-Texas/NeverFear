extends Node

var player = ["res://Scenes/Hero.tscn", "res://Scenes/Survivor.tscn"]
var legacy = "res://Scenes/LegacyProtocol.tscn"
var gauntlet = "res://Scenes/HypercoreGauntlet.tscn"
var lives: int = 3  
var checkpoint_position: Vector2 = Vector2(353.993, -306.008)
var hub_world_position: Vector2 = Vector2(144.501, -387.5)
var returning_from_game: bool = false  # Flag to track return state

# Function to spawn the player at the correct position
func spawn_player():
	var player_instance = player.instantiate()  # Create the player
	
	# Determine the correct spawn position
	if returning_from_game:
		player_instance.global_position = hub_world_position  # Returning to hub
		returning_from_game = false  # Reset the flag
	else:
		player_instance.global_position = checkpoint_position  # Normal start position
	
	get_parent().add_child(player_instance)  # Add player to the scene

# Call this function when entering the Hub World
func enter_hub_world():
	returning_from_game = true  # Set the flag so the player spawns correctly
 
func reset_game_state():
	checkpoint_position = Vector2(353.993, -306.008) # Starting position
	lives = 3  # Reset lives to the initial value
	Engine.time_scale = 1.0
	GameManager.reset_scene_kills()

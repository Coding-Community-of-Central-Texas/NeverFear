extends Node

var player = ["res://Scenes/Hero.tscn", "res://Scenes/Survivor.tscn"]
var legacy = "res://Scenes/LegacyProtocol.tscn"
var gauntlet = "res://Scenes/HypercoreGauntlet.tscn"
var hub = "res://Scenes/HubWorld.tscn"
var lives: int = 3  
var checkpoint_position: Vector2 = Vector2(353.993, -306.008)
var hub_world_position: Vector2 = Vector2(144.501, -387.5)
var returning_from_game: bool = false  # Flag to track return state

func _ready():
	if Engine.has_singleton("IntegrityChecker"):
		var checker = Engine.get_singleton("IntegrityChecker")
		checker.connect("integrity_token_received", Callable(self, "_on_integrity_token_received"))
		checker.connect("integrity_error", Callable(self, "_on_integrity_error"))
		checker.checkIntegrity()

func _on_integrity_token_received(token: String):
	print("Integrity Token: ", token)
# Send to your server for verification

func _on_integrity_error(error: String):
	print("Integrity Error: ", error)


func _on_sign_in_button_pressed():
	if Engine.has_singleton("AuthManager"):
		var auth = Engine.get_singleton("AuthManager")
		auth.connect("sign_in_success", Callable(self, "_on_sign_in_success"))
		auth.connect("sign_in_error", Callable(self, "_on_sign_in_error"))
		auth.signIn()

func _on_sign_in_success(id_token: String):
	print("Signed in, ID Token: ", id_token)

func _on_sign_in_error(error: String):
	print("Sign-in error: ", error)
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

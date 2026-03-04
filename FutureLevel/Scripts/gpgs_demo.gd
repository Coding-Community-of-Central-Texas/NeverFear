extends Node


@onready var play: PlayGames = $PlayGames



func _ready() -> void:
	if Engine.has_singleton("GodotGooglePlayGameServicesV2"):
# If using autoload PlayGames, comment the next 2 lines and use get_node("/root/PlayGames")
		#add_child(play)
		play.signed_in.connect(_on_signed_in)
		play.player_info.connect(_on_player_info)
		play.lb_score.connect(_on_lb_score)
		play.lb_submitted.connect(_on_lb_submitted)


# Optional demo ops
# play.sign_in_interactive()
# play.request_oauth("YOUR_WEB_CLIENT_ID.apps.googleusercontent.com")
# play.show_achievements()
# play.show_leaderboard("YOUR_LEADERBOARD_ID")
# play.submit_score("YOUR_LEADERBOARD_ID", 1234)
# play.fetch_score("YOUR_LEADERBOARD_ID")
	else:
		push_warning("Plugin not found: GodotGooglePlayGameServicesV2")


func _on_signed_in(success: bool, err: String) -> void:
	print("Signed in:", success, " err:", err)


func _on_player_info(success: bool, json: String) -> void:
	print("Player info success:", success, " payload:", json)


func _on_lb_score(success: bool, score: int, err: String) -> void:
	print("LB score success:", success, " score:", score, " err:", err)


func _on_lb_submitted(success: bool, err: String) -> void:
	print("LB submit success:", success, " err:", err)

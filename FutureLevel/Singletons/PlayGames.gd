extends Node
class_name PlayGames

var _gpgs: Object

signal signed_in(success: bool, error: String)
signal player_info(success: bool, json: String)
signal oauth(success: bool, code_or_error: String)
signal lb_score(success: bool, score: int, error: String)
signal lb_submitted(success: bool, error: String)

func _ready() -> void:
	if Engine.has_singleton("GodotGooglePlayGameServicesV2"):
		_gpgs = Engine.get_singleton("GodotGooglePlayGameServicesV2")
		_gpgs.connect("on_sign_in_complete", Callable(self, "_on_sign_in"))
		_gpgs.connect("on_player_info_received", Callable(self, "_on_player_info"))
		_gpgs.connect("on_oauth_code_received", Callable(self, "_on_oauth"))
		_gpgs.connect("on_leaderboard_score_received", Callable(self, "_on_lb_score"))
		_gpgs.connect("on_score_submitted", Callable(self, "_on_lb_submitted"))
		_gpgs.initialize()

func sign_in_interactive() -> void:
	_gpgs.manualSignIn()

func request_oauth(web_client_id: String) -> void:
	_gpgs.requestOAuthAuthCode(web_client_id)

func submit_score(board: String, score: int) -> void:
	_gpgs.submitScoreToLeaderboard(board, score)

func fetch_score(board: String, span := 2, coll := 0) -> void:
	_gpgs.getCurrentPlayerLeaderboardScore(board, span, coll)

# Signal bridges
func _on_sign_in(s: bool, e: String) -> void: emit_signal("signed_in", s, e)
func _on_player_info(s: bool, j: String) -> void: emit_signal("player_info", s, j)
func _on_oauth(s: bool, c: String) -> void: emit_signal("oauth", s, c)
func _on_lb_score(s: bool, score: int, e: String) -> void: emit_signal("lb_score", s, score, e)
func _on_lb_submitted(s: bool, e: String) -> void: emit_signal("lb_submitted", s, e)

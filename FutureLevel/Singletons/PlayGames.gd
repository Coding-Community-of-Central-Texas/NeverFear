extends Node
class_name PlayGames

enum Backend {
	NONE,
	GOOGLE_PLAY_GAMES,
	GAME_CENTER,
}

const GOOGLE_PLAY_PLUGIN_NAME := "GpgsPlugin"
const GAME_CENTER_MANAGER_CLASS := "GameCenterManager"
const GAME_CENTER_ACHIEVEMENT_CLASS := "GKAchievement"
const GAME_CENTER_LEADERBOARD_CLASS := "GKLeaderboard"
const GAME_CENTER_VIEW_CONTROLLER_CLASS := "GKGameCenterViewController"

const GAME_CENTER_PLAYER_SCOPE_GLOBAL := 0
const GAME_CENTER_TIME_SCOPE_ALL_TIME := 2
const GAME_CENTER_VIEW_LEADERBOARDS := 1
const GAME_CENTER_VIEW_ACHIEVEMENTS := 2

# These identifiers must match the Game Center records configured in App Store Connect.
const IOS_ACHIEVEMENT_IDS := {
	"CgkI_v7o0NMNEAIQAg": "001", # first_kill
	"CgkI_v7o0NMNEAIQBQ": "002", # Legacy Completion
	"CgkI_v7o0NMNEAIQBg": "003", # No Deaths
	"CgkI_v7o0NMNEAIQBw": "004", # 9 lives
	"CgkI_v7o0NMNEAIQCQ": "005", # 1-3 min finish
	"CgkI_v7o0NMNEAIQCg": "006", # Finish in 2.5 min
	"CgkI_v7o0NMNEAIQCw": "007", # 2 min or less
	"CgkI_v7o0NMNEAIQDA": "008", # 25elims
	"CgkI_v7o0NMNEAIQDQ": "009", # 300 Elims
	"CgkI_v7o0NMNEAIQDg": "010", # Rank 3
	"CgkI_v7o0NMNEAIQDw": "011", # Rank 4
}

const IOS_LEADERBOARD_IDS := {
	"CgkI_v7o0NMNEAIQFA": "neverfear.legacy_protocol_best_time",
}

var _backend := Backend.NONE
var _gpgs: Object = null
var _game_center: Object = null
var _game_center_local_player: Object = null
var _initialized := false
var _game_center_auto_login_requested := false
var _game_center_login_in_progress := false

signal signed_in
signal sign_in_failed(code: int, error: String)
signal signed_out
signal achievements_ui_closed
signal leaderboard_ui_closed
signal score_submitted(leaderboard_id: String, score: int)
signal achievement_unlocked(achievement_id: String)
signal achievement_incremented(achievement_id: String, steps: int)

func _ready() -> void:
	_init_service()

func _init_service() -> void:
	if _initialized:
		return

	match OS.get_name():
		"Android":
			_init_google_play_games()
		"iOS":
			_init_game_center()
		_:
			push_warning("Game services are only available on Android and iOS")

func _init_google_play_games() -> void:
	if not Engine.has_singleton(GOOGLE_PLAY_PLUGIN_NAME):
		push_error("%s singleton not found" % GOOGLE_PLAY_PLUGIN_NAME)
		return

	_gpgs = Engine.get_singleton(GOOGLE_PLAY_PLUGIN_NAME)

	if _gpgs == null:
		push_error("Failed to get %s singleton" % GOOGLE_PLAY_PLUGIN_NAME)
		return

	_gpgs.connect("gpgs_signed_in", Callable(self, "_on_google_signed_in"))
	_gpgs.connect("gpgs_sign_in_failed", Callable(self, "_on_google_sign_in_failed"))
	_gpgs.connect("gpgs_signed_out", Callable(self, "_on_google_signed_out"))
	_gpgs.connect("gpgs_achievements_ui_closed", Callable(self, "_on_google_achievements_ui_closed"))
	_gpgs.connect("gpgs_leaderboard_ui_closed", Callable(self, "_on_google_leaderboard_ui_closed"))
	_gpgs.connect("gpgs_score_submitted", Callable(self, "_on_google_score_submitted"))
	_gpgs.connect("gpgs_achievement_unlocked", Callable(self, "_on_google_achievement_unlocked"))
	_gpgs.connect("gpgs_achievement_incremented", Callable(self, "_on_google_achievement_incremented"))

	_gpgs.init()
	_backend = Backend.GOOGLE_PLAY_GAMES
	_initialized = true
	print("Google Play Games plugin initialized")

func _init_game_center() -> void:
	if not ClassDB.class_exists(GAME_CENTER_MANAGER_CLASS):
		push_error("Game Center classes not found. Install the GodotApplePlugins GameCenter addon before exporting for iOS.")
		return

	_game_center = ClassDB.instantiate(GAME_CENTER_MANAGER_CLASS)

	if _game_center == null:
		push_error("Failed to create %s" % GAME_CENTER_MANAGER_CLASS)
		return

	_game_center.connect("authentication_result", Callable(self, "_on_game_center_authentication_result"))
	_game_center.connect("authentication_error", Callable(self, "_on_game_center_authentication_error"))
	_refresh_game_center_player()

	_backend = Backend.GAME_CENTER
	_initialized = true
	print("Game Center plugin initialized")
	_queue_game_center_auto_login()

func is_available() -> bool:
	return _initialized and _backend != Backend.NONE

func is_signed_in() -> bool:
	if not is_available():
		return false

	match _backend:
		Backend.GOOGLE_PLAY_GAMES:
			return _gpgs.is_signed_in()
		Backend.GAME_CENTER:
			return _is_game_center_authenticated()

	return false

func sign_in_interactive() -> void:
	if not is_available():
		push_error("Game services not initialized before sign-in")
		return

	match _backend:
		Backend.GOOGLE_PLAY_GAMES:
			_gpgs.sign_in()
		Backend.GAME_CENTER:
			if _game_center_login_in_progress:
				return
			_game_center_login_in_progress = true
			_game_center.call("authenticate")

func sign_out() -> void:
	if not is_available():
		push_error("Game services not initialized before sign-out")
		return

	match _backend:
		Backend.GOOGLE_PLAY_GAMES:
			_gpgs.sign_out()
		Backend.GAME_CENTER:
			push_warning("Game Center sign-out is managed by iOS Settings")

func show_achievements() -> void:
	if not is_available():
		push_error("Game services not initialized before show_achievements")
		return

	match _backend:
		Backend.GOOGLE_PLAY_GAMES:
			_gpgs.show_achievements()
		Backend.GAME_CENTER:
			if not _is_game_center_authenticated():
				push_error("Cannot show Game Center achievements: player is not authenticated")
				return
			ClassDB.class_call_static(GAME_CENTER_VIEW_CONTROLLER_CLASS, "show_type", GAME_CENTER_VIEW_ACHIEVEMENTS)

func unlock_achievement(achievement_id: String) -> void:
	if not is_available():
		push_error("Game services not initialized before unlock_achievement")
		return

	match _backend:
		Backend.GOOGLE_PLAY_GAMES:
			_gpgs.unlock_achievement(achievement_id)
		Backend.GAME_CENTER:
			_report_game_center_achievement(achievement_id, 100.0, true)

func increment_achievement(achievement_id: String, steps: int) -> void:
	if not is_available():
		push_error("Game services not initialized before increment_achievement")
		return

	match _backend:
		Backend.GOOGLE_PLAY_GAMES:
			_gpgs.increment_achievement(achievement_id, steps)
		Backend.GAME_CENTER:
			_report_game_center_achievement(achievement_id, clampf(float(steps), 0.0, 100.0), false, steps)

func show_leaderboard(leaderboard_id: String) -> void:
	if not is_available():
		push_error("Game services not initialized before show_leaderboard")
		return

	match _backend:
		Backend.GOOGLE_PLAY_GAMES:
			_gpgs.show_leaderboard(leaderboard_id)
		Backend.GAME_CENTER:
			var game_center_leaderboard_id := _get_game_center_leaderboard_id(leaderboard_id)
			if game_center_leaderboard_id.is_empty():
				return
			if not _is_game_center_authenticated():
				push_error("Cannot show Game Center leaderboard: player is not authenticated")
				return
			ClassDB.class_call_static(
				GAME_CENTER_VIEW_CONTROLLER_CLASS,
				"show_leaderboard_time_period",
				game_center_leaderboard_id,
				GAME_CENTER_PLAYER_SCOPE_GLOBAL,
				GAME_CENTER_TIME_SCOPE_ALL_TIME
			)

func submit_score(leaderboard_id: String, score: int) -> void:
	if not is_available():
		push_error("Game services not initialized before submit_score")
		return

	match _backend:
		Backend.GOOGLE_PLAY_GAMES:
			_gpgs.submit_score(leaderboard_id, score)
		Backend.GAME_CENTER:
			_submit_game_center_score(leaderboard_id, score)

func _refresh_game_center_player() -> void:
	if _game_center == null:
		_game_center_local_player = null
		return

	_game_center_local_player = _game_center.get("local_player")

func _queue_game_center_auto_login() -> void:
	if _game_center_auto_login_requested:
		return

	_game_center_auto_login_requested = true
	call_deferred("_run_game_center_auto_login")

func _run_game_center_auto_login() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_game_center_auto_login_requested = false

	if not is_available() or _backend != Backend.GAME_CENTER:
		return

	if _is_game_center_authenticated():
		emit_signal("signed_in")
		return

	print("Starting Game Center auto login")
	sign_in_interactive()

func _is_game_center_authenticated() -> bool:
	_refresh_game_center_player()
	if _game_center_local_player == null:
		return false

	return bool(_game_center_local_player.get("is_authenticated"))

func _get_game_center_achievement_id(achievement_id: String) -> String:
	var mapped_id := String(IOS_ACHIEVEMENT_IDS.get(achievement_id, ""))
	if mapped_id.is_empty():
		push_warning("No Game Center achievement ID mapped for %s; skipping iOS achievement report" % achievement_id)
	return mapped_id

func _get_game_center_leaderboard_id(leaderboard_id: String) -> String:
	var mapped_id := String(IOS_LEADERBOARD_IDS.get(leaderboard_id, ""))
	if mapped_id.is_empty():
		push_error("No Game Center leaderboard ID mapped for %s" % leaderboard_id)
	return mapped_id

func _report_game_center_achievement(
	achievement_id: String,
	percent_complete: float,
	show_completion_banner: bool,
	increment_steps := 0
) -> void:
	var game_center_achievement_id := _get_game_center_achievement_id(achievement_id)
	if game_center_achievement_id.is_empty():
		return

	if not _is_game_center_authenticated():
		push_error("Cannot report Game Center achievement: player is not authenticated")
		return

	if not ClassDB.class_exists(GAME_CENTER_ACHIEVEMENT_CLASS):
		push_error("%s class not found" % GAME_CENTER_ACHIEVEMENT_CLASS)
		return

	var achievement: Object = null
	if ClassDB.class_has_method(GAME_CENTER_ACHIEVEMENT_CLASS, "make"):
		achievement = ClassDB.class_call_static(GAME_CENTER_ACHIEVEMENT_CLASS, "make", game_center_achievement_id)
	else:
		achievement = ClassDB.instantiate(GAME_CENTER_ACHIEVEMENT_CLASS)
		achievement.set("identifier", game_center_achievement_id)

	if achievement == null:
		push_error("Failed to create Game Center achievement %s" % game_center_achievement_id)
		return

	achievement.set("percent_complete", percent_complete)
	achievement.set("shows_completion_banner", show_completion_banner)

	ClassDB.class_call_static(
		GAME_CENTER_ACHIEVEMENT_CLASS,
		"report_achievement",
		[achievement],
		Callable(self, "_on_game_center_achievement_reported").bind(achievement_id, increment_steps)
	)

func _submit_game_center_score(leaderboard_id: String, score: int) -> void:
	var game_center_leaderboard_id := _get_game_center_leaderboard_id(leaderboard_id)
	if game_center_leaderboard_id.is_empty():
		return

	if not _is_game_center_authenticated():
		push_error("Cannot submit Game Center score: player is not authenticated")
		return

	if not ClassDB.class_exists(GAME_CENTER_LEADERBOARD_CLASS):
		push_error("%s class not found" % GAME_CENTER_LEADERBOARD_CLASS)
		return

	ClassDB.class_call_static(
		GAME_CENTER_LEADERBOARD_CLASS,
		"load_leaderboards",
		PackedStringArray([game_center_leaderboard_id]),
		Callable(self, "_on_game_center_leaderboards_loaded").bind(leaderboard_id, score)
	)

func _on_game_center_leaderboards_loaded(leaderboards: Array, error: Variant, leaderboard_id: String, score: int) -> void:
	if error != null:
		push_error("Failed to load Game Center leaderboard %s: %s" % [leaderboard_id, _format_game_center_error(error)])
		return

	if leaderboards.is_empty():
		push_error("Game Center leaderboard %s was not found" % leaderboard_id)
		return

	var leaderboard: Object = leaderboards[0]
	_refresh_game_center_player()
	if leaderboard == null or _game_center_local_player == null:
		push_error("Cannot submit Game Center score: leaderboard or local player is missing")
		return

	leaderboard.call(
		"submit_score",
		score,
		0,
		_game_center_local_player,
		Callable(self, "_on_game_center_score_submitted").bind(leaderboard_id, score)
	)

func _on_game_center_score_submitted(error: Variant, leaderboard_id: String, score: int) -> void:
	if error != null:
		push_error("Failed to submit Game Center score for %s: %s" % [leaderboard_id, _format_game_center_error(error)])
		return

	emit_signal("score_submitted", leaderboard_id, score)

func _on_game_center_achievement_reported(error: Variant, achievement_id: String, increment_steps: int) -> void:
	if error != null:
		push_error("Failed to report Game Center achievement %s: %s" % [achievement_id, _format_game_center_error(error)])
		return

	if increment_steps > 0:
		emit_signal("achievement_incremented", achievement_id, increment_steps)
	else:
		emit_signal("achievement_unlocked", achievement_id)

func _format_game_center_error(error: Variant) -> String:
	if error == null:
		return ""
	return str(error)

func _on_google_signed_in() -> void:
	emit_signal("signed_in")

func _on_google_sign_in_failed(code: int, error: String) -> void:
	emit_signal("sign_in_failed", code, error)

func _on_google_signed_out() -> void:
	emit_signal("signed_out")

func _on_google_achievements_ui_closed() -> void:
	emit_signal("achievements_ui_closed")

func _on_google_leaderboard_ui_closed() -> void:
	emit_signal("leaderboard_ui_closed")

func _on_google_score_submitted(leaderboard_id: String, score: int) -> void:
	emit_signal("score_submitted", leaderboard_id, score)

func _on_google_achievement_unlocked(achievement_id: String) -> void:
	emit_signal("achievement_unlocked", achievement_id)

func _on_google_achievement_incremented(achievement_id: String, steps: int) -> void:
	emit_signal("achievement_incremented", achievement_id, steps)

func _on_game_center_authentication_result(status: bool) -> void:
	_game_center_login_in_progress = false
	_refresh_game_center_player()
	if status:
		emit_signal("signed_in")
	else:
		emit_signal("sign_in_failed", 0, "Game Center authentication failed")

func _on_game_center_authentication_error(error: String) -> void:
	_game_center_login_in_progress = false
	emit_signal("sign_in_failed", 0, error)

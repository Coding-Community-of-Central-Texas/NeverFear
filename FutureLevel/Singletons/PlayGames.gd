extends Node
class_name PlayGames

var _gpgs: Object = null
var _initialized := false

signal signed_in
signal sign_in_failed(code: int, error: String)
signal signed_out
signal achievements_ui_closed
signal leaderboard_ui_closed
signal score_submitted(leaderboard_id: String, score: int)
signal achievement_unlocked(achievement_id: String)
signal achievement_incremented(achievement_id: String, steps: int)

const PLUGIN_NAME := "GpgsPlugin"

func _ready() -> void:
	_init_plugin()

func _init_plugin() -> void:
	if _initialized:
		return

	if OS.get_name() != "Android":
		push_warning("GPGS plugin is only available on Android")
		return

	if not Engine.has_singleton(PLUGIN_NAME):
		push_error("%s singleton not found" % PLUGIN_NAME)
		return

	_gpgs = Engine.get_singleton(PLUGIN_NAME)

	if _gpgs == null:
		push_error("Failed to get %s singleton" % PLUGIN_NAME)
		return

	_gpgs.connect("gpgs_signed_in", Callable(self, "_on_signed_in"))
	_gpgs.connect("gpgs_sign_in_failed", Callable(self, "_on_sign_in_failed"))
	_gpgs.connect("gpgs_signed_out", Callable(self, "_on_signed_out"))
	_gpgs.connect("gpgs_achievements_ui_closed", Callable(self, "_on_achievements_ui_closed"))
	_gpgs.connect("gpgs_leaderboard_ui_closed", Callable(self, "_on_leaderboard_ui_closed"))
	_gpgs.connect("gpgs_score_submitted", Callable(self, "_on_score_submitted"))
	_gpgs.connect("gpgs_achievement_unlocked", Callable(self, "_on_achievement_unlocked"))
	_gpgs.connect("gpgs_achievement_incremented", Callable(self, "_on_achievement_incremented"))

	_gpgs.init()
	_initialized = true
	print("GPGS plugin initialized")

func is_available() -> bool:
	return _initialized and _gpgs != null

func is_signed_in() -> bool:
	if not is_available():
		return false
	return _gpgs.is_signed_in()

func sign_in_interactive() -> void:
	if not is_available():
		push_error("GPGS not initialized before sign-in")
		return
	_gpgs.sign_in()

func sign_out() -> void:
	if not is_available():
		push_error("GPGS not initialized before sign-out")
		return
	_gpgs.sign_out()

func show_achievements() -> void:
	if not is_available():
		push_error("GPGS not initialized before show_achievements")
		return
	_gpgs.show_achievements()

func unlock_achievement(achievement_id: String) -> void:
	if not is_available():
		push_error("GPGS not initialized before unlock_achievement")
		return
	_gpgs.unlock_achievement(achievement_id)

func increment_achievement(achievement_id: String, steps: int) -> void:
	if not is_available():
		push_error("GPGS not initialized before increment_achievement")
		return
	_gpgs.increment_achievement(achievement_id, steps)

func show_leaderboard(leaderboard_id: String) -> void:
	if not is_available():
		push_error("GPGS not initialized before show_leaderboard")
		return
	_gpgs.show_leaderboard(leaderboard_id)

func submit_score(leaderboard_id: String, score: int) -> void:
	if not is_available():
		push_error("GPGS not initialized before submit_score")
		return
	_gpgs.submit_score(leaderboard_id, score)

func _on_signed_in() -> void:
	emit_signal("signed_in")

func _on_sign_in_failed(code: int, error: String) -> void:
	emit_signal("sign_in_failed", code, error)

func _on_signed_out() -> void:
	emit_signal("signed_out")

func _on_achievements_ui_closed() -> void:
	emit_signal("achievements_ui_closed")

func _on_leaderboard_ui_closed() -> void:
	emit_signal("leaderboard_ui_closed")

func _on_score_submitted(leaderboard_id: String, score: int) -> void:
	emit_signal("score_submitted", leaderboard_id, score)

func _on_achievement_unlocked(achievement_id: String) -> void:
	emit_signal("achievement_unlocked", achievement_id)

func _on_achievement_incremented(achievement_id: String, steps: int) -> void:
	emit_signal("achievement_incremented", achievement_id, steps)

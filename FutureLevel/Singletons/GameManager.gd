extends Node

signal cash
signal game_cash_changed(current_cash: int)
signal kill
signal scene_kill_updated(kills: int)
signal player_jumped()
signal player_double_jumped()
signal life_collected()


var http_request = "res://Scenes/HTTPRequest.tscn"

const ACHIEVEMENT_SHARP_SHOOTER = "CgkI_v7o0NMNEAIQAg"
const ACHIEVEMENT_JUMP = "CgkI_v7o0NMNEAIQAw"
const ACHIEVEMENT_DOUBLE_JUMP_II = "CgkI_v7o0NMNEAIQBA"
const ACHIEVEMENT_COMPLETE_LEGACY_STAGE_1 = "CgkI_v7o0NMNEAIQBQ"
const ACHIEVEMENT_NO_DEATHS = "CgkI_v7o0NMNEAIQBg"
const ACHIEVEMENT_CAT_LOVER = "CgkI_v7o0NMNEAIQBw"
const ACHIEVEMENT_STACKS_ON_STACKS = "CgkI_v7o0NMNEAIQCA"
const ACHIEVEMENT_PRETTY_QUICK_FELLA = "CgkI_v7o0NMNEAIQCQ"
const ACHIEVEMENT_WHOA_FAST_GUY = "CgkI_v7o0NMNEAIQCg"
const ACHIEVEMENT_ZZOOOMM = "CgkI_v7o0NMNEAIQCw"
const ACHIEVEMENT_25_ELIMINATIONS = "CgkI_v7o0NMNEAIQDA"
const ACHIEVEMENT_HYPERCORE_UNDERTAKER = "CgkI_v7o0NMNEAIQDQ"
const ACHIEVEMENT_MY_STRENGTH_IS_GROWING = "CgkI_v7o0NMNEAIQDg"
const ACHIEVEMENT_FURTHER_BEYOND = "CgkI_v7o0NMNEAIQDw"
const LEADERBOARD_LEGACY_PROTOCOL_BEST_TIME = "CgkI_v7o0NMNEAIQFA"
const LEGACY_PROTOCOL_3_MIN_MS := 180000
const LEGACY_PROTOCOL_2_5_MIN_MS := 150000

# Stats
var total_kills: int = 0
var quickest_time: String = "99:59.999"
var longest_survival: String = "00:00.000"
var total_cash: int = 0
var current_level_time: String = "" 
var current_kills: int = 0
var game_cash: int = 0 
var api_key: String 
var player_name: String
# File path for save data
const SAVE_PATH = "user://stat_data.json"
var deaths_in_legacy_protocol: int = 0
var lives_collected_in_playthrough: int = 0
var current_level: String = ""

var sharp_shooter_unlocked = false
var jump_unlocked = false
var double_jump_unlocked = false
var stacks_on_stacks_unlocked = false
var eliminations_25_unlocked = false
var hypercore_undertaker_unlocked = false
var complete_legacy_stage_1_unlocked := false
var no_deaths_unlocked := false
var cat_lover_unlocked := false
var pretty_quick_fella_unlocked := false
var rank_3_achievement_sent := false
var whoa_fast_guy_unlocked := false


# API Endpoint URL
const API_URL: String = "https://neverfearendpoint-469126233982.us-south1.run.app"
var API_KEY: String

func _init():
	# Connect signals to handlers
	self.connect("player_jumped", Callable(self, "_on_player_jumped"))
	self.connect("player_double_jumped", Callable(self, "_on_player_double_jumped"))
	self.connect("cash", Callable(self, "_on_cash_collected"))
	self.connect("life_collected", Callable(self, "_on_life_collected"))


func _on_kill(amount: int) -> void:
	total_kills += amount
	current_kills += amount  # Increment current scene kills
	# Emit a signal for the current scene's kills
	emit_signal("scene_kill_updated", current_kills)
	
	if total_kills >= 1 and not sharp_shooter_unlocked:
		sharp_shooter_unlocked = true
		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_SHARP_SHOOTER)

	if total_kills >= 25 and not eliminations_25_unlocked:
		eliminations_25_unlocked = true
		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_25_ELIMINATIONS)


	if total_kills >= 300 and not hypercore_undertaker_unlocked:
		hypercore_undertaker_unlocked = true
		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_HYPERCORE_UNDERTAKER)
			

func on_legacy_protocol_completed(final_time: String) -> void:
	if not complete_legacy_stage_1_unlocked:
		complete_legacy_stage_1_unlocked = true
		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_COMPLETE_LEGACY_STAGE_1)

	if deaths_in_legacy_protocol == 0 and not no_deaths_unlocked:
		no_deaths_unlocked = true
		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_NO_DEATHS)
			
	check_legacy_protocol_speed_achievements(final_time)
	save_data()

func check_lives_achievement() -> void:
	if Global.lives >= 9 and not cat_lover_unlocked:
		cat_lover_unlocked = true

		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_CAT_LOVER)

		save_data()

func start_legacy_protocol_run() -> void:
	current_level = "LegacyProtocol"
	deaths_in_legacy_protocol = 0

func register_player_death() -> void:
	if current_level == "LegacyProtocol":
		deaths_in_legacy_protocol += 1

func check_legacy_protocol_speed_achievements(final_time: String) -> void:
	if final_time.is_empty():
		push_error("Legacy Protocol completion time is empty")
		return

	if not final_time.contains(":") or not final_time.contains("."):
		push_error("Legacy Protocol completion time has invalid format: " + final_time)
		return

	var run_ms := time_to_ms(final_time)

	if run_ms <= LEGACY_PROTOCOL_3_MIN_MS and not pretty_quick_fella_unlocked:
		pretty_quick_fella_unlocked = true
		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_PRETTY_QUICK_FELLA)

	if run_ms <= LEGACY_PROTOCOL_2_5_MIN_MS and not whoa_fast_guy_unlocked:
		whoa_fast_guy_unlocked = true
		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_WHOA_FAST_GUY)
			print("Legacy Protocol under 2.5 minutes achievement unlock request sent")

func _on_rank_changed(rank_index: int) -> void:
	if rank_index >= 2 and not rank_3_achievement_sent:
		rank_3_achievement_sent = true

		if playgames.is_available() and playgames.is_signed_in():
			playgames.unlock_achievement(ACHIEVEMENT_MY_STRENGTH_IS_GROWING)
			print("Rank 3 achievement unlock request sent")

func reset_scene_kills() -> void:
	# Reset scene-specific kill counter
	current_kills = 0
	game_cash = 0
	emit_signal("game_cash_changed", game_cash)

func add_cash(amount: int):
	game_cash += amount
	total_cash += amount
	emit_signal("game_cash_changed", game_cash)
	if total_cash >= 696969 and not stacks_on_stacks_unlocked:
		playgames.unlock_achievement(ACHIEVEMENT_STACKS_ON_STACKS)
		stacks_on_stacks_unlocked = true

func spend_game_cash(amount: int) -> bool:
	if amount <= 0:
		return true
	if game_cash < amount:
		return false
	game_cash -= amount
	emit_signal("game_cash_changed", game_cash)
	return true

# Update the quickest time
func update_quickest_time(time: String):
	if time_to_ms(time) < time_to_ms(quickest_time) or quickest_time == "99:59.999":
		quickest_time = time
		print("New quickest time: ", quickest_time)
		save_data()  # Save updated quickest time

# Convert time (MM:SS.MS) to milliseconds
func time_to_ms(time: String) -> int:
	var parts = time.split(":")
	var minutes = int(parts[0])
	var seconds_and_msec = parts[1].split(".")
	var seconds = int(seconds_and_msec[0])
	var msec = int(seconds_and_msec[1])
	return (minutes * 60 + seconds) * 1000 + msec

# Update the longest survival time
func update_longest_survival(time: String) -> void:
	if time_to_ms(time) > time_to_ms(longest_survival) or longest_survival == "00:00.000":
		longest_survival = time
		print("New longest survival time:", longest_survival)
		save_data()  # Save updated survival time

# Save game data to a file
func save_data():
	var data = {
		"total_kills": total_kills,
		"quickest_time": quickest_time,
		"longest_survival": longest_survival,
		"total_cash": total_cash,
		"complete_legacy_stage_1_unlocked": complete_legacy_stage_1_unlocked,
		"cat_lover_unlocked": cat_lover_unlocked,
		"whoa_fast_guy_unlocked": whoa_fast_guy_unlocked
	}
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(data))
		save_file.close()

# Load game data from a file
func load_data():
	if FileAccess.file_exists(SAVE_PATH):
		var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if save_file:
			var raw_text = save_file.get_as_text()
			var data = JSON.parse_string(raw_text)
			save_file.close()
			if typeof(data) == TYPE_DICTIONARY:
				total_kills = data.get("total_kills", 0)
				quickest_time = data.get("quickest_time", "99:59.999")
				longest_survival = data.get("longest_survival", "00:00.000")
				total_cash = data.get("total_cash", 0)
				complete_legacy_stage_1_unlocked = data.get("complete_legacy_stage_1_unlocked", false)
				cat_lover_unlocked = data.get("cat_lover_unlocked", false)
				whoa_fast_guy_unlocked = data.get("whoa_fast_guy_unlocked", false)
				print("Game data loaded successfully")
			else:
				print("Error: Failed to parse save data")
	else:
		print("No save file found, starting with default values")

func submit_best_legacy_protocol_time() -> void:
	if quickest_time.is_empty():
		push_error("Cannot submit best time: quickest_time is empty")
		return

	if not quickest_time.contains(":") or not quickest_time.contains("."):
		push_error("Cannot submit best time: invalid quickest_time format: " + quickest_time)
		return

	var best_time_ms := time_to_ms(quickest_time)
	print("Submitting quickest_time: ", quickest_time, " = ", best_time_ms, " ms")

	if playgames.is_available() and playgames.is_signed_in():
		playgames.submit_score(LEADERBOARD_LEGACY_PROTOCOL_BEST_TIME, best_time_ms)
	else:
		push_error("Cannot submit leaderboard score: Play Games not available or not signed in")

# Save data when exiting the game
func _on_tree_exiting():
	save_data()

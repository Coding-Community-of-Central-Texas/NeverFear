extends Node

signal cash_collected(amount: int)
signal scene_kill_updated(kills: int)
signal send_data
signal player_jumped()
signal player_double_jumped()
signal enemy_killed(enemy_type)
signal life_collected()

var achievements_client
var autosave_timer


# Achievement IDs
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
var deaths_in_legacy_protocol: int = 0
var lives_collected_in_playthrough: int = 0
var current_level: String = ""

# Flags for achievements that should only be awarded once per player profile
var sharp_shooter_unlocked = false
var jump_unlocked = false
var double_jump_unlocked = false
var stacks_on_stacks_unlocked = false
var eliminations_25_unlocked = false
var hypercore_undertaker_unlocked = false


# File path for save data
const SAVE_PATH: String = "user://stat_data.json"

# API Endpoint URL
const API_URL: String = "https://neverfearendpoint-469126233982.us-south1.run.app"
var API_KEY: String


func load_game_data():
	if GodotPlayGameServices.initialize():
		achievements_client = GodotPlayGameServices.achievements

func _init():
	# Connect signals to handlers
	self.connect("player_jumped", Callable(self, "_on_player_jumped"))
	self.connect("player_double_jumped", Callable(self, "_on_player_double_jumped"))
	self.connect("enemy_killed", Callable(self, "_on_enemy_killed"))
	self.connect("cash_collected", Callable(self, "_on_cash_collected"))
	self.connect("life_collected", Callable(self, "_on_life_collected"))
	
	# Set up autosave timer
	autosave_timer = Timer.new()
	autosave_timer.wait_time = 60 # Save every 60 seconds
	autosave_timer.autostart = true
	autosave_timer.connect("timeout", Callable(self, "save_data"))
	add_child(autosave_timer)

func _ready():
	load_game_data()
	load_data()
	GodotPlayGameServices.initialize()

func _on_enemy_killed(enemy_type) -> void:
	load_game_data()
	total_kills += 1
	current_kills += 1  # Increment current scene kills
	# Emit a signal for the current scene's kills
	emit_signal("scene_kill_updated", current_kills)
	
	# Check for total kill achievements
	if total_kills >= 1 and not sharp_shooter_unlocked:
		unlock_achievement(ACHIEVEMENT_SHARP_SHOOTER)
		sharp_shooter_unlocked = true
	if total_kills >= 25 and not eliminations_25_unlocked:
		unlock_achievement(ACHIEVEMENT_25_ELIMINATIONS)
		eliminations_25_unlocked = true
	if total_kills >= 300 and not hypercore_undertaker_unlocked:
		unlock_achievement(ACHIEVEMENT_HYPERCORE_UNDERTAKER)
		hypercore_undertaker_unlocked = true

func _on_cash_collected(amount: int):
	game_cash += amount
	total_cash += amount

	# Check for total cash achievement
	if total_cash >= 1000000 and not stacks_on_stacks_unlocked:
		unlock_achievement(ACHIEVEMENT_STACKS_ON_STACKS)
		stacks_on_stacks_unlocked = true

func _on_life_collected():
	lives_collected_in_playthrough += 1
	if lives_collected_in_playthrough >= 9:
		unlock_achievement(ACHIEVEMENT_CAT_LOVER)


func reset_scene_stats() -> void:
	# Reset scene-specific kill counter and cash
	current_kills = 0
	game_cash = 0


# Update the quickest time
func update_quickest_time(time: String):
	if time_to_ms(time) < time_to_ms(quickest_time) or quickest_time == "99:59.999":
		quickest_time = time
		print("New quickest time: ", quickest_time)

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

# Save game data to a file
func save_data():
	var data = {
		"total_kills": total_kills,
		"quickest_time": quickest_time,
		"longest_survival": longest_survival,
		"total_cash": total_cash,
		"sharp_shooter_unlocked": sharp_shooter_unlocked,
		"jump_unlocked": jump_unlocked,
		"double_jump_unlocked": double_jump_unlocked,
		"stacks_on_stacks_unlocked": stacks_on_stacks_unlocked,
		"eliminations_25_unlocked": eliminations_25_unlocked,
		"hypercore_undertaker_unlocked": hypercore_undertaker_unlocked
	}
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(data))
		save_file.close()
		print("Game data saved successfully.")
	else:
		print("Error: Failed to save game data.")

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
				sharp_shooter_unlocked = data.get("sharp_shooter_unlocked", false)
				jump_unlocked = data.get("jump_unlocked", false)
				double_jump_unlocked = data.get("double_jump_unlocked", false)
				stacks_on_stacks_unlocked = data.get("stacks_on_stacks_unlocked", false)
				eliminations_25_unlocked = data.get("eliminations_25_unlocked", false)
				hypercore_undertaker_unlocked = data.get("hypercore_undertaker_unlocked", false)
				print("Game data loaded successfully")
			else:
				print("Error: Failed to parse save data")
	else:
		print("No save file found, starting with default values")

# Save data when exiting the game
func _on_tree_exiting():
	save_data()

func send_stats(http_request: HTTPRequest) -> void:
	var headers = [
		"Content-Type: application/json",
		"x-api-key: " + API_KEY  # Add API key in the header
	]
	
	var payload = {
		"player_name": player_name,
		"total_kills": total_kills,
		"quickest_time": quickest_time,
		"longest_survival": longest_survival,
		"total_cash": total_cash
	}
	
	var json_payload = JSON.stringify(payload)
	var error = http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_payload)
	
	if error != OK:
		push_error("Failed to send data! Error code: " + str(error))
	else:
		print("API request sent successfully.")

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Response Code: ", response_code)
	var response_text = body.get_string_from_utf8()
	var parsed_response = JSON.parse_string(response_text)

	if parsed_response is Dictionary:
		print("Server Response: ", parsed_response)
	else:
		push_error("Failed to parse response JSON")

func unlock_achievement(achievement_id: String):
	if achievements_client != null:
		var result = achievements_client.unlock(achievement_id)
		if result != OK:
			print("Error unlocking achievement ", achievement_id, ": ", result)
		
func player_died():
	if current_level == "Legacy Protocol":
		deaths_in_legacy_protocol += 1

func player_won():
	pass

func reset_legacy_protocol_stats():
	deaths_in_legacy_protocol = 0
	lives_collected_in_playthrough = 0

func _on_player_jumped():
	if not jump_unlocked:
		unlock_achievement(ACHIEVEMENT_JUMP)
		jump_unlocked = true
		save_data()

func _on_player_double_jumped():
	if not double_jump_unlocked:
		unlock_achievement(ACHIEVEMENT_DOUBLE_JUMP_II)
		double_jump_unlocked = true
		save_data()

func complete_legacy_protocol(time_in_ms: int):
	unlock_achievement(ACHIEVEMENT_COMPLETE_LEGACY_STAGE_1)
	
	if deaths_in_legacy_protocol == 0:
		unlock_achievement(ACHIEVEMENT_NO_DEATHS)
		
	if time_in_ms <= time_to_ms("03:00.000"):
		unlock_achievement(ACHIEVEMENT_PRETTY_QUICK_FELLA)
		if time_in_ms <= time_to_ms("02:30.000"):
			unlock_achievement(ACHIEVEMENT_WHOA_FAST_GUY)
			if time_in_ms <= time_to_ms("02:00.000"):
				unlock_achievement(ACHIEVEMENT_ZZOOOMM)
			
	reset_legacy_protocol_stats()

func reach_survival_gauntlet_rank(rank: int):
	if rank >= 3:
		unlock_achievement(ACHIEVEMENT_MY_STRENGTH_IS_GROWING)
	if rank >= 4:
		unlock_achievement(ACHIEVEMENT_FURTHER_BEYOND)

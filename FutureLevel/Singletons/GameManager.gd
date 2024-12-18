extends Node

signal kill
signal cash
signal scene_kill_updated(kills: int)

# Stats
var total_kills: int = 0
var quickest_time: String = "99:59.999"
var longest_survival: String = "00:00.000"
var total_cash: int = 0
var current_level_time: String = "" 
var current_kills: int = 0
var game_cash: int = 0 

# File path for save data
const SAVE_PATH = "user://save_data.json"

func _ready():
	load_data()

func _on_kill(amount: int) -> void:
	total_kills += amount
	current_kills += amount  # Increment current scene kills

	# Emit a signal for the current scene's kills
	emit_signal("scene_kill_updated", current_kills)
	save_data()  # Save updated stats

func reset_scene_kills() -> void:
	# Reset scene-specific kill counter
	current_kills = 0

func add_cash(amount: int):
	game_cash += amount

func finalize_cash():
	total_cash += game_cash
	game_cash = 0
	print("Level Cash Added to Total. Total Cash: $", total_cash)
	save_data()  # Save updated cash stats

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
func update_longest_survival(time: String):
	if time_to_ms(time) < time_to_ms(longest_survival) or longest_survival == "00:00.000":
		longest_survival = time
		print("New longest survival time:", longest_survival)
		save_data()  # Save updated survival time



# Save game data to a file
func save_data():
	var data = {
		"total_kills": total_kills,
		"quickest_time": quickest_time,
		"longest_survival": longest_survival,
		"total_cash": total_cash
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
				print("Game data loaded successfully")
			else:
				print("Error: Failed to parse save data")
	else:
		print("No save file found, starting with default values")

# Save data when exiting the game
func _on_tree_exiting():
	finalize_cash()
	save_data()

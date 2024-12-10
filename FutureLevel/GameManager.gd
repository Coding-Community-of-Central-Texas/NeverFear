extends Node

signal kill
signal cash

# Stats
var total_kills: int = 0
var quickest_time: String = "99:59.999"
var longest_survival: int = 0
var total_cash: int = 0
var current_level_time: String = "" 


# File path for save data
const SAVE_PATH = "user://save_data.json"

func _ready():
	load_data()



# Function to add kills
func _on_kill():
	total_kills += 1
	print("Kill +1")

# Function to update the quickest time for Legacy Protocol
func update_quickest_time(time: String):
	# Convert the time (MM:SS.MS) into total milliseconds for comparison
	var new_time_ms = time_to_ms(time)
	var quickest_time_ms = time_to_ms(quickest_time)

	if new_time_ms < quickest_time_ms or quickest_time == "00:00.000":  # First time or new record
		quickest_time = time
		print("New quickest time: ", quickest_time)

# Function to convert time (MM:SS.MS) to milliseconds
func time_to_ms(time: String) -> int:
	var parts = time.split(":")
	var minutes = int(parts[0])
	var seconds_and_msec = parts[1].split(".")
	var seconds = int(seconds_and_msec[0])
	var msec = int(seconds_and_msec[1])
	return (minutes * 60 + seconds) * 1000 + msec


# Function to update the longest survival time for Hypercore Override
func update_longest_survival(time: int):
	if time > longest_survival:
		longest_survival = time

# Function to add cash


# Save game data
func save_data():
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file:
		var data = {
			"total_kills": total_kills,
			"quickest_time": quickest_time,
			"longest_survival": longest_survival,
			"total_cash": total_cash
		}
		save_file.store_string(JSON.stringify(data))
		save_file.close()

# Load game data
func load_data():
	if FileAccess.file_exists(SAVE_PATH):
		var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if save_file:
			# Attempt to parse the file contents
			var raw_text = save_file.get_as_text()
			var data = JSON.parse_string(raw_text)
			save_file.close()
			
			# Check if parsing was successful
			if typeof(data) == TYPE_DICTIONARY and "error" in data:
				if data["error"] == OK:
					if "result" in data:
						var parsed_data = data["result"]
						total_kills = parsed_data.get("total_kills", 0)
						quickest_time = parsed_data.get("quickest_time", "99:59.999")
						longest_survival = parsed_data.get("longest_survival", 0)
						total_cash = parsed_data.get("total_cash", 0)
						return
					else:
						print("Error: 'result' key missing in parsed data.")
				else:
					print("Error parsing JSON: Code", data["error"])
			else:
				print("Error: Unexpected data format or missing 'error' key.")
	else:
		print("Save file does not exist.")
# Debug print for stats
func print_stats():
	print("Total Kills:", total_kills)
	print("Quickest Time:", quickest_time)
	print("Longest Survival:", longest_survival)
	print("Total Cash:", total_cash)


var game_cash: float = 0

func _on_add_cash(amount: float) -> void:
	game_cash += amount

func add_total_cash():
	game_cash += total_cash

@export var pause_scene: PackedScene = preload("res://Scenes/PauseMenu.tscn")
var pause_instance: Node = null

func toggle_pause():
	if get_tree().paused:
		# Unpause
		get_tree().paused = false
		if pause_instance and pause_instance.is_inside_tree():
			pause_instance.queue_free()
			pause_instance = null
		else:
			get_tree().paused = true
			if not pause_instance:
				pause_instance = pause_scene.instantiate()
				get_tree().current_scene.add_child(pause_instance)

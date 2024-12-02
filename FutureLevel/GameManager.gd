extends Node

# Stats
var total_kills: int = 0
var quickest_time: int = INF  
var longest_survival: int = 0
var total_cash: int = 0


# File path for save data
const SAVE_PATH = "user://save_data.json"

func _ready():
	load_data()



# Function to add kills
func add_kill():
	total_kills += 1

# Function to update the quickest time for Legacy Protocol
func update_quickest_time(time: int):
	if time < quickest_time:
		quickest_time = time

# Function to update the longest survival time for Hypercore Override
func update_longest_survival(time: int):
	if time > longest_survival:
		longest_survival = time

# Function to add cash
func add_cash(amount: int):
	total_cash += amount

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
			var data = JSON.parse_string(save_file.get_as_text())
			save_file.close()
			if data.error == OK:
				var parsed_data = data.result
				total_kills = parsed_data.get("total_kills", 0)
				quickest_time = parsed_data.get("quickest_time", INF)
				longest_survival = parsed_data.get("longest_survival", 0)
				total_cash = parsed_data.get("total_cash", 0)

# Debug print for stats
func print_stats():
	print("Total Kills:", total_kills)
	print("Quickest Time:", quickest_time)
	print("Longest Survival:", longest_survival)
	print("Total Cash:", total_cash)

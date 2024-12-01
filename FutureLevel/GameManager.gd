extends Node

var total_kills: int = 0 
var quickest_time: int = 0
var finish: int = 0

func _on_kill() -> void:
	total_kills += 1 

func _level_complete():
	if finish > quickest_time:
		finish = quickest_time
	else:
		return


func ready():
	var data = load_data_android()
	total_kills = data.total_kills
	quickest_time = data.quickest_time if data.quickest_time != null else INF
	print("Total kills:", total_kills, "Quickest time:", quickest_time)
var save_path = "user://save_data.json"

func save_data_android(total_kills: int, quickest_time: int):
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		var json = JSON.new()
		var data = {
			"total_kills": total_kills,
			"quickest_time": quickest_time 
			}
		save_file.store_string(JSON.stringify(data))
		save_file.close()

func load_data_android() -> Dictionary:
	if FileAccess.file_exists("user://save_data.json"):
		var save_file = FileAccess.open("user://save_data.json", FileAccess.READ)
		if save_file:
			var json = JSON.new()
			var parsed = json.parse(save_file.get_as_text())
			save_file.close()
			
			if parsed.error == OK:
				return parsed.result
			else:
				print("Failed to parse JSON: ", parsed.error_string)
	return {"total_kills": 0, "quickest_time": null}

enum music {
	AGONY,
	EVIL,
	DARKNESS,
}

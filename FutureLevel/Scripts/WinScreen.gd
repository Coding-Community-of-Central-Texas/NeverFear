extends TextureRect

@onready var label: Label = $StatsLink/Label
@onready var run_time: Label = $RunTime


func _ready():
	if DisplayServer.is_touchscreen_available() and OS.has_feature("Andriod"):
		get_viewport().screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	else:
		return
	Engine.time_scale = 1.0
	Global.reset_game_state()

func _process(_delta):
	run_time.text = "YOUR COMPLETION TIME: d%" % %LegacyProtocol.total_time
	




func _on_stats_link_pressed() -> void:
	Engine.time_scale = 1.0
	Global.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/PerformanceIndex.tscn")

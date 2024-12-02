extends Node

@export var game_manager: NodePath 
@onready var manager = get_node(game_manager)
@onready var timer: Timer = $Timer

var start_time: int

func _ready():
	Global.legacy = self
	$Timer.start()
	start_time = Time.get_ticks_msec()
	if DisplayServer.is_touchscreen_available() and OS.has_feature("Andriod"):
		get_viewport().screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	else:
		return

func complete_level():
	var elapsed_time = Time.get_ticks_msec() - start_time
	GameManager.update_quickest_time(elapsed_time)
	GameManager.save_data()

func _on_tree_exiting():
	
	var level_time = $Timer.time_elapsed
	

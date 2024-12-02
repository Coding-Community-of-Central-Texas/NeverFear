extends Node
signal kill 
@export var game_manager: NodePath 
@onready var manager = get_node(game_manager)

var start_time: int

func _ready():
	start_time = Time.get_ticks_msec()
	if DisplayServer.is_touchscreen_available() and OS.has_feature("Andriod"):
		get_viewport().screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	else:
		return

func complete_level():
	var elapsed_time = Time.get_ticks_msec() - start_time
	manager.update_quickest_time(elapsed_time)
	manager.save_data()
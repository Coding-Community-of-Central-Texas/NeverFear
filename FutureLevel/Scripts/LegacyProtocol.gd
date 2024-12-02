extends Node

@export var game_manager: NodePath 
@onready var manager = get_node(game_manager)

var start_time: int

func _ready():
	start_time = Time.get_ticks_msec()

func complete_level():
	var elapsed_time = Time.get_ticks_msec() - start_time
	manager.update_quickest_time(elapsed_time)
	manager.save_data()

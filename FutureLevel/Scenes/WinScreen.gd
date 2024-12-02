extends TextureRect

@onready var label_2: Label = $Label2


func _ready():
	if DisplayServer.is_touchscreen_available() and OS.has_feature("Andriod"):
		get_viewport().screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	else:
		return
	Engine.time_scale = 1.0
	Global.reset_game_state()

func _process(delta):
	label_2.text = "YOUR COMPLETION TIME: d%" % Global.legacy.total_time
	

#func completion_time():
	#var elapsed_time = Time.get_ticks_msec() - start_time

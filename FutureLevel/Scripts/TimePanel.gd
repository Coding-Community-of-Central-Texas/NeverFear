extends Panel


@onready var minutes_timer: Label = $Minutes
@onready var seconds_timer: Label = $Seconds
@onready var msec_timer: Label = $Msec




var time: float = 0.0
var minutes: int = 0
var seconds: int = 0
var msec: int = 0 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	time += delta
	msec = fmod(time, 1) * 100 
	seconds = fmod(time, 60)
	minutes = fmod(time, 3600) / 60
	$Minutes.text = "%02d:" % minutes
	$Seconds.text = "%02d." % seconds
	$Msec.text = "%03d" % msec

func get_time_formated() -> String:
	return "%02d:%02d.%03d" % [minutes, seconds, msec]

func stop():
	var formatted_time = get_time_formated()
	set_process(false)
	return formatted_time


func _on_legacy_protocol_end_level() -> void:
	stop()

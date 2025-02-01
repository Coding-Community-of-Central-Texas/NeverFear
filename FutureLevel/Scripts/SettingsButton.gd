extends Panel

@onready var credits: TouchScreenButton = $Icons34/Credits


func _on_settings_button_pressed():
	Displaysetting.show_settings()

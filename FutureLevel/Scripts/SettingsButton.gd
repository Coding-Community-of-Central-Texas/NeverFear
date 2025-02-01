extends Panel

@onready var credits: TouchScreenButton = $Icons34/Credits



func _on_credits_pressed() -> void:
	get_tree().change_scene_to("res://Singletons/Displaysetting.tscn")

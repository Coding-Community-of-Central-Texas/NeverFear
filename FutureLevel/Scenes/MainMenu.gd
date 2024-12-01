extends Control

@onready var legacy_protocol: TouchScreenButton = $CanvasLayer/VBoxContainer/MenuBox/HBoxContainer/LegacyProtocol
@onready var hypercore_gauntlet: TouchScreenButton = $CanvasLayer/VBoxContainer/MenuBox/Label2/HypercoreGauntlet



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if DisplayServer.is_touchscreen_available():
		get_viewport().screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	else:
		return






func _on_legacy_protocol_pressed() -> void:
	Global.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")


func _on_hypercore_gauntlet_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/HypercoreGauntlet.tscn")

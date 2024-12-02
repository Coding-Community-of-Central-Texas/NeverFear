extends Control

@onready var legacy_protocol: TouchScreenButton = $MenuBox/Story/LegacyProtocol
@onready var hypercore_gauntlet: TouchScreenButton = $MenuBox/Survival/HypercoreGauntlet
@onready var performance: TouchScreenButton = $MenuBox/PerformanceSettings/Performance
@onready var credits: TouchScreenButton = $MenuBox/Credits/Credits



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if DisplayServer.is_touchscreen_available() and OS.has_feature("Andriod"):
		get_viewport().screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	else:
		return


func _on_legacy_protocol_pressed() -> void:
	Global.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/LegacyProtocol.tscn")


func _on_hypercore_gauntlet_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/HypercoreGauntlet.tscn")
	Global.reset_game_state()


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Credits.tscn")

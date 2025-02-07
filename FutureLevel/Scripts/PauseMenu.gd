extends Control


@onready var continuebutton: Label = $Panel/ContinueButton/Continue
@onready var home: Label = $Panel/Homebutton/Home
@onready var restart: Label = $Panel/Restartbutton/Restart
@onready var credits: Sprite2D = $Panel/Credits
@onready var sfx: CheckButton = $Panel/SFX
@onready var music: CheckButton = $Panel/Music

func _ready() -> void:
	get_tree().paused = true

func _on_continue_game_pressed() -> void:
	get_tree().paused = false
	%AudioStreamPlayer2D.play()
	continuebutton.modulate = Color(0.5, 0.5, 0)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	continuebutton.modulate = Color(1, 1, 1, 1)  # Reset to normal
	queue_free()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	%AudioStreamPlayer2D.play()
	restart.modulate = Color(0.5, 0.5, 0)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	restart.modulate = Color(1, 1, 1, 1)  # Reset to normal
	Global.reset_game_state()
	GameManager.reset_scene_kills()
	get_tree().reload_current_scene()

func _on_home_pressed() -> void:
	get_tree().paused = false
	%AudioStreamPlayer2D.play()
	home.modulate = Color(0.5, 0.5, 0)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	home.modulate = Color(1, 1, 1, 1)  # Reset to normal
	GameManager.reset_scene_kills()
	Global.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/HubWorld.tscn")

func _on_credits_pressed() -> void:
	get_tree().paused = false
	%AudioStreamPlayer2D.play()
	credits.modulate = Color(0.5, 0.5, 0, 0.7)  # Set to red
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	credits.modulate = Color(1, 1, 1, 1)  # Reset to normal
	get_tree().change_scene_to_file("res://Scenes/Credits.tscn")

func _on_sfx_toggled(toggled_on: bool) -> void:
	if sfx.toggled:
		sfx.toggled_on = true
		AudioServer.set_bus_mute(1, false)
	else:
		sfx.toggled_on = false
		AudioServer.set_bus_mute(1, true)

func _on_music_toggled(toggled_on: bool) -> void:
	if music.toggled:
		music.toggled_on = true
		AudioServer.set_bus_mute(2, false)
	else:
		music.toggled_on = false
		AudioServer.set_bus_mute(2, true)

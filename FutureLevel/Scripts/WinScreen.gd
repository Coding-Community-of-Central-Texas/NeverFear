extends CanvasLayer


@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D
@onready var enimies_killed: Label = $Win/EnimiesKilled
@onready var cash_collected: Label = $Win/CashCollected
@onready var run_time: Label = $Win/RunTime

func _ready() -> void:
	GameManager.on_legacy_protocol_completed(Global.legacy.level_time())

func _process(_delta):
	run_time.text = "run time: %s" % Global.legacy.level_time()
	enimies_killed.text = "bots vaporized: %d" % GameManager.current_kills
	cash_collected.text = "cash collected:  %s" % GameManager.format_cash(GameManager.game_cash)

func _on_stats_link_pressed() -> void:
	audio_stream_player_2d.play()
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	Engine.time_scale = 1.0
	Global.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/HubWorld.tscn")

func _on_restart_pressed() -> void:
	audio_stream_player_2d.play()
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	Engine.time_scale = 1.0
	Global.reset_game_state()
	get_tree().reload_current_scene()

func _on_credits_2_pressed() -> void:
	get_tree().paused = false
	%AudioStreamPlayer2D.play()
	await get_tree().create_timer(0.2).timeout  # Wait for 0.1 seconds
	get_tree().change_scene_to_file("res://Scenes/Credits.tscn")

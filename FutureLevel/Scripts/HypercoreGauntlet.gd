extends Node2D

@export var wave_duration_seconds: float = 90.0

@onready var survivor: CharacterBody2D = $Survivor
@onready var time_panel: Panel = %TimePanel

var current_wave: int = 1
var wave_timer: Timer
var shop_layer: CanvasLayer

func _ready() -> void:
	Global.gauntlet = self
	_setup_wave_timer()
	call_deferred("_start_current_wave")

func _on_scene_transition() -> void:
	GameManager.reset_scene_kills()

func time_survived():
	# Call stop() on the timer and get the formatted time
	var formatted_time = time_panel.get_time_formated()  # Now it will call the stop function from the Panel script
	GameManager.update_longest_survival(formatted_time)  # Pass the formatted time to the GameManager
	GameManager.save_data()  # Save the game data

func _on_survivor_playerdeath():
	if wave_timer:
		wave_timer.stop()

	%TimePanel.stop()
	time_survived()

func _setup_wave_timer() -> void:
	wave_timer = Timer.new()
	wave_timer.name = "WaveTimer"
	wave_timer.one_shot = true
	wave_timer.wait_time = wave_duration_seconds
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	add_child(wave_timer)

func _start_current_wave() -> void:
	_start_gauntlet_spawners()
	wave_timer.start(wave_duration_seconds)

func _on_wave_timer_timeout() -> void:
	_end_current_wave()

func _end_current_wave() -> void:
	_stop_gauntlet_spawners()
	_despawn_enemies()
	_show_shop_screen()
	get_tree().paused = true

func _start_gauntlet_spawners() -> void:
	for spawner in get_tree().get_nodes_in_group("gauntlet_spawner"):
		if spawner.has_method("start_wave"):
			spawner.call("start_wave", current_wave)

func _stop_gauntlet_spawners() -> void:
	for spawner in get_tree().get_nodes_in_group("gauntlet_spawner"):
		if spawner.has_method("stop_spawning"):
			spawner.call("stop_spawning")

func _despawn_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()

func _show_shop_screen() -> void:
	if shop_layer and is_instance_valid(shop_layer):
		shop_layer.queue_free()

	shop_layer = CanvasLayer.new()
	shop_layer.name = "WaveShop"
	shop_layer.layer = 100
	shop_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(shop_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.025, 0.04, 0.82)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_layer.add_child(backdrop)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260.0
	panel.offset_top = -170.0
	panel.offset_right = 260.0
	panel.offset_bottom = 170.0
	backdrop.add_child(panel)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 28.0
	content.offset_top = 26.0
	content.offset_right = -28.0
	content.offset_bottom = -26.0
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)

	var title := Label.new()
	title.text = "WAVE %d COMPLETE" % current_wave
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	content.add_child(title)

	var body := Label.new()
	body.text = "Placeholder shop screen\nSpend rewards here later, then resume to start the next wave."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 22)
	content.add_child(body)

	var resume_button := Button.new()
	resume_button.text = "RESUME WAVE %d" % (current_wave + 1)
	resume_button.custom_minimum_size = Vector2(0, 70)
	resume_button.add_theme_font_size_override("font_size", 26)
	resume_button.pressed.connect(_on_shop_resume_pressed)
	content.add_child(resume_button)

func _on_shop_resume_pressed() -> void:
	if shop_layer and is_instance_valid(shop_layer):
		shop_layer.queue_free()
		shop_layer = null

	current_wave += 1
	get_tree().paused = false
	_start_current_wave()

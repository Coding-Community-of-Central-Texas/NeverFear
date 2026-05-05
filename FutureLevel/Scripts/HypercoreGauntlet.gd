extends Node2D

@export var wave_duration_seconds: float = 90.0

const COUNTDOWN_VISIBLE_SECONDS: float = 10.0
const SHOP_ITEMS := [
	{
		"id": "repair",
		"title": "repair kit",
		"description": "+175 health",
		"cost": 6000
	},
	{
		"id": "overclock",
		"title": "overclock boots",
		"description": "+40 move speed",
		"cost": 8000
	},
	{
		"id": "life",
		"title": "backup core",
		"description": "+1 life",
		"cost": 14000
	}
]

@onready var survivor: CharacterBody2D = $Survivor
@onready var time_panel: Panel = %TimePanel
@onready var hud_layer: CanvasLayer = $CanvasLayer

var current_wave: int = 1
var wave_timer: Timer
var shop_layer: CanvasLayer
var wave_hud_panel: PanelContainer
var wave_label: Label
var wave_countdown_label: Label
var shop_cash_label: Label
var shop_feedback_label: Label
var shop_item_buttons: Array[Button] = []

func _ready() -> void:
	Global.gauntlet = self
	if not GameManager.game_cash_changed.is_connected(_on_game_cash_changed):
		GameManager.game_cash_changed.connect(_on_game_cash_changed)
	_setup_wave_timer()
	_setup_wave_hud()
	call_deferred("_start_current_wave")

func _process(_delta: float) -> void:
	_update_wave_hud()

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

func _setup_wave_hud() -> void:
	wave_hud_panel = PanelContainer.new()
	wave_hud_panel.name = "WaveHud"
	wave_hud_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	wave_hud_panel.offset_left = 28.0
	wave_hud_panel.offset_top = 148.0
	wave_hud_panel.offset_right = 260.0
	wave_hud_panel.offset_bottom = 238.0
	wave_hud_panel.custom_minimum_size = Vector2(232.0, 90.0)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.03, 0.055, 0.82)
	panel_style.border_color = Color(0.15, 0.83, 1.0, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	wave_hud_panel.add_theme_stylebox_override("panel", panel_style)
	hud_layer.add_child(wave_hud_panel)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 16)
	margins.add_theme_constant_override("margin_top", 10)
	margins.add_theme_constant_override("margin_right", 16)
	margins.add_theme_constant_override("margin_bottom", 10)
	wave_hud_panel.add_child(margins)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	margins.add_child(content)

	wave_label = Label.new()
	wave_label.text = "wave 1"
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.add_theme_color_override("font_color", Color(0.78, 0.97, 1.0, 1.0))
	wave_label.add_theme_color_override("font_outline_color", Color.BLACK)
	wave_label.add_theme_constant_override("outline_size", 7)
	wave_label.add_theme_font_size_override("font_size", 30)
	content.add_child(wave_label)

	wave_countdown_label = Label.new()
	wave_countdown_label.text = ""
	wave_countdown_label.visible = false
	wave_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.36, 0.18, 1.0))
	wave_countdown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	wave_countdown_label.add_theme_constant_override("outline_size", 7)
	wave_countdown_label.add_theme_font_size_override("font_size", 24)
	content.add_child(wave_countdown_label)

	_update_wave_hud()

func _start_current_wave() -> void:
	_start_gauntlet_spawners()
	wave_timer.start(wave_duration_seconds)
	_update_wave_hud()

func _on_wave_timer_timeout() -> void:
	_end_current_wave()

func _end_current_wave() -> void:
	_stop_gauntlet_spawners()
	_despawn_enemies()
	_show_shop_screen()
	_update_wave_hud()
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

	shop_item_buttons.clear()
	shop_cash_label = null
	shop_feedback_label = null

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
	panel.offset_left = -330.0
	panel.offset_top = -280.0
	panel.offset_right = 330.0
	panel.offset_bottom = 280.0
	backdrop.add_child(panel)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 28.0
	content.offset_top = 26.0
	content.offset_right = -28.0
	content.offset_bottom = -26.0
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	var title := Label.new()
	title.text = "wave %d complete" % current_wave
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	content.add_child(title)

	shop_cash_label = Label.new()
	shop_cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_cash_label.add_theme_color_override("font_color", Color(1.0, 0.83, 0.27, 1.0))
	shop_cash_label.add_theme_font_size_override("font_size", 28)
	content.add_child(shop_cash_label)

	var item_list := VBoxContainer.new()
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 10)
	content.add_child(item_list)

	for item in SHOP_ITEMS:
		item_list.add_child(_create_shop_item_row(item))

	shop_feedback_label = Label.new()
	shop_feedback_label.text = ""
	shop_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_feedback_label.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0, 1.0))
	shop_feedback_label.add_theme_font_size_override("font_size", 18)
	content.add_child(shop_feedback_label)

	var resume_button := Button.new()
	resume_button.text = "resume wave %d" % (current_wave + 1)
	resume_button.custom_minimum_size = Vector2(0, 60)
	resume_button.add_theme_font_size_override("font_size", 24)
	resume_button.pressed.connect(_on_shop_resume_pressed)
	content.add_child(resume_button)

	_refresh_shop_cash()

func _create_shop_item_row(item: Dictionary) -> Control:
	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(0, 82)

	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color(0.045, 0.055, 0.085, 0.92)
	row_style.border_color = Color(0.16, 0.42, 0.52, 0.9)
	row_style.set_border_width_all(1)
	row_style.set_corner_radius_all(8)
	row_panel.add_theme_stylebox_override("panel", row_style)

	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 14)
	margins.add_theme_constant_override("margin_top", 8)
	margins.add_theme_constant_override("margin_right", 12)
	margins.add_theme_constant_override("margin_bottom", 8)
	row_panel.add_child(margins)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margins.add_child(row)

	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", 2)
	row.add_child(text_stack)

	var item_title := Label.new()
	item_title.text = String(item["title"])
	item_title.add_theme_font_size_override("font_size", 22)
	text_stack.add_child(item_title)

	var item_description := Label.new()
	item_description.text = "%s  -  %d cash" % [String(item["description"]), int(item["cost"])]
	item_description.add_theme_color_override("font_color", Color(0.74, 0.82, 0.86, 1.0))
	item_description.add_theme_font_size_override("font_size", 16)
	text_stack.add_child(item_description)

	var buy_button := Button.new()
	buy_button.custom_minimum_size = Vector2(128, 54)
	buy_button.add_theme_font_size_override("font_size", 20)
	buy_button.set_meta("item_id", String(item["id"]))
	buy_button.set_meta("cost", int(item["cost"]))
	buy_button.pressed.connect(_on_shop_item_pressed.bind(item))
	row.add_child(buy_button)
	shop_item_buttons.append(buy_button)

	return row_panel

func _on_shop_item_pressed(item: Dictionary) -> void:
	var item_id := String(item["id"])
	var item_title := String(item["title"])
	var cost := int(item["cost"])

	if not _shop_item_has_effect(item_id):
		_set_shop_feedback("%s is already maxed." % item_title)
		return

	if not GameManager.spend_game_cash(cost):
		_set_shop_feedback("not enough cash for %s." % item_title)
		return

	_apply_shop_item(item_id)
	_set_shop_feedback("%s purchased." % item_title)
	_refresh_shop_cash()

func _apply_shop_item(item_id: String) -> void:
	match item_id:
		"repair":
			Global.player.health = min(Global.player.MAX_HEALTH, Global.player.health + 175.0)
			Global.player.health_bar.value = Global.player.health
		"overclock":
			Global.player.SPEED += 40.0
		"life":
			Global.lives += 1
			GameManager.check_lives_achievement()

func _shop_item_has_effect(item_id: String) -> bool:
	if Global.player == null or not is_instance_valid(Global.player):
		return false

	match item_id:
		"repair":
			return Global.player.health < Global.player.MAX_HEALTH
		"overclock", "life":
			return true

	return false

func _refresh_shop_cash() -> void:
	if shop_cash_label and is_instance_valid(shop_cash_label):
		shop_cash_label.text = "cash bank: %06d" % GameManager.game_cash

	for button in shop_item_buttons:
		if not is_instance_valid(button):
			continue

		var item_id := String(button.get_meta("item_id"))
		var cost := int(button.get_meta("cost"))
		button.disabled = GameManager.game_cash < cost or not _shop_item_has_effect(item_id)
		button.text = "buy\n%d" % cost

func _set_shop_feedback(message: String) -> void:
	if shop_feedback_label and is_instance_valid(shop_feedback_label):
		shop_feedback_label.text = message

func _on_game_cash_changed(_current_cash: int) -> void:
	if shop_layer and is_instance_valid(shop_layer):
		_refresh_shop_cash()

func _on_shop_resume_pressed() -> void:
	if shop_layer and is_instance_valid(shop_layer):
		shop_layer.queue_free()
		shop_layer = null

	current_wave += 1
	get_tree().paused = false
	_start_current_wave()

func _update_wave_hud() -> void:
	if wave_hud_panel == null or not is_instance_valid(wave_hud_panel):
		return

	var shop_is_open := shop_layer != null and is_instance_valid(shop_layer)
	wave_hud_panel.visible = not shop_is_open
	wave_label.text = "wave %d" % current_wave

	if shop_is_open or wave_timer == null or wave_timer.is_stopped():
		wave_countdown_label.visible = false
		return

	var remaining := wave_timer.time_left
	if remaining > 0.0 and remaining <= COUNTDOWN_VISIBLE_SECONDS:
		var seconds_left := int(ceil(remaining))
		if seconds_left < 1:
			seconds_left = 1
		elif seconds_left > int(COUNTDOWN_VISIBLE_SECONDS):
			seconds_left = int(COUNTDOWN_VISIBLE_SECONDS)

		wave_countdown_label.visible = true
		wave_countdown_label.text = "shop in %02d" % seconds_left
	else:
		wave_countdown_label.visible = false

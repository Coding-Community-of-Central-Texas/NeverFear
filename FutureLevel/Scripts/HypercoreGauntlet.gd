extends Node2D

@export var wave_duration_seconds: float = 90.0

const COUNTDOWN_VISIBLE_SECONDS: float = 10.0
const AUTO_GRENADE_THROW_FORCE: float = 760.0
const AUTO_GRENADE_SPAWN_OFFSET: float = 28.0
const AUTO_GRENADE_SEQUENCE_DELAY: float = 0.35
const CASH_PICKUP_MIN := 40000
const CASH_PICKUP_MAX := 90000
const AUTO_GRENADE_SCENE := preload("res://Scenes/granade.tscn")
const WAVE_SHOP_SCENE := preload("res://Scenes/WaveShop.tscn")
const SHOP_OFFER_COUNT := 4
const AUTO_GRENADE_TIERS := [
	{
		"description": "nearest enemy every 9 sec",
		"cost": 2000000,
		"cooldown": 9.0,
		"grenades": 1
	},
	{
		"description": "nearest enemy every 6 sec",
		"cost": 3000000,
		"cooldown": 6.0,
		"grenades": 1
	},
	{
		"description": "two staggered grenades every 3 sec",
		"cost": 4500000,
		"cooldown": 3.0,
		"grenades": 2
	}
]
const PLASMA_BALL_TIERS := [
	{
		"description": "top plasma ball (-Y start)",
		"cost": 2200000
	},
	{
		"description": "bottom plasma ball (+Y start)",
		"cost": 2200000
	},
	{
		"description": "left plasma ball (-X start)",
		"cost": 2200000
	},
	{
		"description": "right plasma ball (+X start)",
		"cost": 2200000
	}
]
const SHOP_ITEMS := [
	{
		"id": "repair",
		"title": "repair kit",
		"description": "+175 health",
		"cost": 600000,
		"badge": "+"
	},
	{
		"id": "overclock",
		"title": "overclock boots",
		"description": "+35 move speed",
		"cost": 800000,
		"badge": ">>"
	},
	{
		"id": "second_gun",
		"title": "second gun",
		"description": "equip an extra rifle",
		"cost": 3000000,
		"badge": "2x"
	},
	{
		"id": "shotgun",
		"title": "shotgun",
		"description": "equip a close-range spread weapon",
		"cost": 2800000,
		"badge": "SG"
	},
	{
		"id": "laser_sniper",
		"title": "laser sniper",
		"description": "long-range piercing laser blast",
		"cost": 3600000,
		"badge": "LS"
	},
	{
		"id": "plasma_ball",
		"title": "plasma orbit",
		"description": "add synced orbiting plasma balls",
		"cost": 2200000,
		"badge": "P"
	},
	{
		"id": "auto_grenade",
		"title": "grenade rig",
		"description": "nearest enemy every 9 sec",
		"cost": 2000000,
		"badge": "G"
	}
]

@onready var survivor: CharacterBody2D = $Survivor
@onready var time_panel: Panel = %TimePanel
@onready var hud_layer: CanvasLayer = $CanvasLayer

var current_wave: int = 1
var wave_timer: Timer
var shop_layer: WaveShop
var wave_hud_panel: PanelContainer
var wave_label: Label
var wave_countdown_label: Label
var auto_grenade_active: bool = false
var auto_grenade_tier: int = 0
var auto_grenade_timer: Timer
var shop_offer_item_ids: Array[String] = []

func _ready() -> void:
	randomize()
	Global.gauntlet = self
	GameManager.start_hypercore_gauntlet_run()
	if not GameManager.game_cash_changed.is_connected(_on_game_cash_changed):
		GameManager.game_cash_changed.connect(_on_game_cash_changed)
	_setup_wave_timer()
	_setup_auto_grenade_timer()
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
	if auto_grenade_timer:
		auto_grenade_timer.stop()

	%TimePanel.stop()
	time_survived()

func _setup_wave_timer() -> void:
	wave_timer = Timer.new()
	wave_timer.name = "WaveTimer"
	wave_timer.one_shot = true
	wave_timer.wait_time = wave_duration_seconds
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	add_child(wave_timer)

func _setup_auto_grenade_timer() -> void:
	auto_grenade_timer = Timer.new()
	auto_grenade_timer.name = "AutoGrenadeTimer"
	auto_grenade_timer.one_shot = false
	auto_grenade_timer.wait_time = _get_auto_grenade_cooldown()
	auto_grenade_timer.timeout.connect(_on_auto_grenade_timer_timeout)
	add_child(auto_grenade_timer)

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
			if enemy.has_method("deactivate"):
				enemy.call("deactivate")
			else:
				enemy.queue_free()

func _show_shop_screen() -> void:
	if shop_layer and is_instance_valid(shop_layer):
		shop_layer.queue_free()

	shop_layer = WAVE_SHOP_SCENE.instantiate() as WaveShop
	add_child(shop_layer)
	shop_layer.purchase_requested.connect(_on_shop_purchase_requested)
	shop_layer.refresh_requested.connect(_on_shop_refresh_requested)
	shop_layer.resume_requested.connect(_on_shop_resume_pressed)
	_reroll_shop_offer_items()
	shop_layer.setup(current_wave, GameManager.game_cash, _get_shop_item_states(shop_offer_item_ids))

func _get_shop_item_states(item_ids: Array[String] = []) -> Array[Dictionary]:
	var item_states: Array[Dictionary] = []
	if not item_ids.is_empty():
		for item_id in item_ids:
			var item := _get_shop_item(item_id)
			if not item.is_empty():
				item_states.append(_get_shop_item_state(item))

		return item_states

	for item in SHOP_ITEMS:
		item_states.append(_get_shop_item_state(item))

	return item_states

func _reroll_shop_offer_items() -> void:
	shop_offer_item_ids = _get_random_shop_offer_item_ids()

func _get_random_shop_offer_item_ids() -> Array[String]:
	var available_items: Array[Dictionary] = []
	var fallback_items: Array[Dictionary] = []

	for item in SHOP_ITEMS:
		var item_id := String(item["id"])
		if _shop_item_has_effect(item_id):
			available_items.append(item)
		else:
			fallback_items.append(item)

	var selected_ids := _pick_random_shop_item_ids(available_items, SHOP_OFFER_COUNT)
	if selected_ids.size() < SHOP_OFFER_COUNT:
		selected_ids.append_array(_pick_random_shop_item_ids(fallback_items, SHOP_OFFER_COUNT - selected_ids.size()))

	return selected_ids

func _pick_random_shop_item_ids(items: Array[Dictionary], count: int) -> Array[String]:
	var shuffled_items := items.duplicate()
	shuffled_items.shuffle()

	var selected_ids: Array[String] = []
	var selected_count: int = min(count, shuffled_items.size())
	for index in range(selected_count):
		selected_ids.append(String(shuffled_items[index]["id"]))

	return selected_ids

func _get_shop_item_state(item: Dictionary) -> Dictionary:
	var item_id := String(item["id"])
	var cost := _get_shop_item_cost(item)
	var has_effect := _shop_item_has_effect(item_id)
	var can_afford := GameManager.game_cash >= cost
	var action_state := "buy"
	var action_text := "buy\n%s" % GameManager.format_cash(cost)
	var plasma_ball_tier := 0
	if item_id == "plasma_ball":
		plasma_ball_tier = _get_plasma_ball_tier()

	if item_id == "auto_grenade" and auto_grenade_tier >= AUTO_GRENADE_TIERS.size():
		action_state = "max"
		action_text = "max"
	elif item_id == "auto_grenade" and auto_grenade_tier > 0:
		action_state = "upgrade"
		action_text = "upgrade\n%s" % GameManager.format_cash(cost)
	elif item_id == "plasma_ball" and plasma_ball_tier >= PLASMA_BALL_TIERS.size():
		action_state = "max"
		action_text = "max"
	elif item_id == "plasma_ball" and plasma_ball_tier > 0:
		action_state = "upgrade"
		action_text = "upgrade\n%s" % GameManager.format_cash(cost)
	elif item_id in ["second_gun", "shotgun", "laser_sniper"] and not has_effect:
		action_state = "equipped"
		action_text = "equipped"
	elif not has_effect:
		action_state = "max"
		action_text = "max"

	return {
		"id": item_id,
		"title": String(item["title"]),
		"description": _get_shop_item_description(item),
		"badge": String(item.get("badge", "")),
		"cost": cost,
		"has_effect": has_effect,
		"can_afford": can_afford,
		"action_state": action_state,
		"action_text": action_text
	}

func _get_shop_item(item_id: String) -> Dictionary:
	for item in SHOP_ITEMS:
		if String(item["id"]) == item_id:
			return item

	return {}

func _on_shop_purchase_requested(item_id: String) -> void:
	var item := _get_shop_item(item_id)
	if item.is_empty():
		return

	var item_title := String(item["title"])
	var cost := _get_shop_item_cost(item)

	if not _shop_item_has_effect(item_id):
		if item_id in ["second_gun", "shotgun", "laser_sniper"]:
			shop_layer.set_feedback("%s already equipped" % item_title, WaveShop.FEEDBACK_WARNING)
		else:
			shop_layer.set_feedback("%s already maxed" % item_title, WaveShop.FEEDBACK_WARNING)
		return

	if not GameManager.spend_game_cash(cost):
		shop_layer.set_feedback("need %s for %s" % [GameManager.format_cash(cost), item_title], WaveShop.FEEDBACK_ERROR)
		return

	_apply_shop_item(item_id)
	shop_layer.set_feedback("%s purchased" % item_title, WaveShop.FEEDBACK_SUCCESS)
	_refresh_shop_cash()

func _on_shop_refresh_requested() -> void:
	if not shop_layer or not is_instance_valid(shop_layer):
		return

	_reroll_shop_offer_items()
	shop_layer.refresh(GameManager.game_cash, _get_shop_item_states(shop_offer_item_ids))
	shop_layer.set_feedback("stock refreshed")

func _apply_shop_item(item_id: String) -> void:
	match item_id:
		"repair":
			Global.player.health = min(Global.player.MAX_HEALTH, Global.player.health + 175.0)
			Global.player.health_bar.value = Global.player.health
		"overclock":
			Global.player.SPEED += 35.0
		"second_gun":
			_buy_second_gun()
		"shotgun":
			_buy_shotgun()
		"laser_sniper":
			_buy_laser_sniper()
		"plasma_ball":
			_buy_orbiting_plasma_ball()
		"auto_grenade":
			_upgrade_auto_grenade()

func _shop_item_has_effect(item_id: String) -> bool:
	if Global.player == null or not is_instance_valid(Global.player):
		return false

	match item_id:
		"repair":
			return Global.player.health < Global.player.MAX_HEALTH
		"overclock":
			return true
		"second_gun":
			return Global.player.has_method("has_second_gun") and not Global.player.call("has_second_gun")
		"shotgun":
			return Global.player.has_method("has_shotgun") and not Global.player.call("has_shotgun")
		"laser_sniper":
			return Global.player.has_method("has_laser_sniper") and not Global.player.call("has_laser_sniper")
		"plasma_ball":
			return _get_plasma_ball_tier() < PLASMA_BALL_TIERS.size()
		"auto_grenade":
			return auto_grenade_tier < AUTO_GRENADE_TIERS.size()

	return false

func _get_shop_item_cost(item: Dictionary) -> int:
	if String(item["id"]) == "auto_grenade":
		if auto_grenade_tier >= AUTO_GRENADE_TIERS.size():
			return 0
		return int(AUTO_GRENADE_TIERS[auto_grenade_tier]["cost"])

	if String(item["id"]) == "plasma_ball":
		var plasma_ball_tier := _get_plasma_ball_tier()
		if plasma_ball_tier >= PLASMA_BALL_TIERS.size():
			return 0
		return int(PLASMA_BALL_TIERS[plasma_ball_tier]["cost"])

	return int(item["cost"])

func _get_shop_item_description(item: Dictionary) -> String:
	if String(item["id"]) == "plasma_ball":
		var plasma_ball_tier := _get_plasma_ball_tier()
		if plasma_ball_tier >= PLASMA_BALL_TIERS.size():
			return "tier 4 active: four synced plasma balls"

		var next_tier: Dictionary = PLASMA_BALL_TIERS[plasma_ball_tier]
		return "tier %d: %s" % [plasma_ball_tier + 1, String(next_tier["description"])]

	if String(item["id"]) == "auto_grenade":
		if auto_grenade_tier >= AUTO_GRENADE_TIERS.size():
			return "tier 3 active: two staggered grenades every 3 sec"

		var next_tier: Dictionary = AUTO_GRENADE_TIERS[auto_grenade_tier]
		return "tier %d: %s" % [auto_grenade_tier + 1, String(next_tier["description"])]

	if String(item["id"]) == "second_gun" and Global.player != null and is_instance_valid(Global.player):
		if Global.player.has_method("has_second_gun") and Global.player.call("has_second_gun"):
			return "extra rifle equipped"

	if String(item["id"]) == "shotgun" and Global.player != null and is_instance_valid(Global.player):
		if Global.player.has_method("has_shotgun") and Global.player.call("has_shotgun"):
			return "shotgun equipped"

	if String(item["id"]) == "laser_sniper" and Global.player != null and is_instance_valid(Global.player):
		if Global.player.has_method("has_laser_sniper") and Global.player.call("has_laser_sniper"):
			return "laser sniper equipped"

	return String(item["description"])

func _refresh_shop_cash() -> void:
	if shop_layer and is_instance_valid(shop_layer):
		shop_layer.refresh(GameManager.game_cash, _get_shop_item_states(shop_offer_item_ids))

func _on_game_cash_changed(_current_cash: int) -> void:
	if shop_layer and is_instance_valid(shop_layer):
		_refresh_shop_cash()

func get_cash_pickup_amount() -> int:
	return randi_range(CASH_PICKUP_MIN, CASH_PICKUP_MAX)

func allows_speed_power_up_drops() -> bool:
	return false

func _upgrade_auto_grenade() -> void:
	if auto_grenade_tier >= AUTO_GRENADE_TIERS.size():
		return

	auto_grenade_tier += 1
	auto_grenade_active = true
	if auto_grenade_timer:
		auto_grenade_timer.stop()
		auto_grenade_timer.wait_time = _get_auto_grenade_cooldown()
		auto_grenade_timer.start(_get_auto_grenade_cooldown())

func _buy_second_gun() -> void:
	if Global.player == null or not is_instance_valid(Global.player):
		return
	if Global.player.has_method("equip_second_gun"):
		Global.player.call("equip_second_gun")

func _buy_shotgun() -> void:
	if Global.player == null or not is_instance_valid(Global.player):
		return
	if Global.player.has_method("equip_shotgun"):
		Global.player.call("equip_shotgun")

func _buy_laser_sniper() -> void:
	if Global.player == null or not is_instance_valid(Global.player):
		return
	if Global.player.has_method("equip_laser_sniper"):
		Global.player.call("equip_laser_sniper")

func _buy_orbiting_plasma_ball() -> void:
	if Global.player == null or not is_instance_valid(Global.player):
		return
	if Global.player.has_method("equip_orbiting_plasma_ball"):
		Global.player.call("equip_orbiting_plasma_ball")

func _get_plasma_ball_tier() -> int:
	if Global.player == null or not is_instance_valid(Global.player):
		return 0

	var plasma_ball_tier := 0
	if Global.player.has_method("get_orbiting_plasma_ball_count"):
		plasma_ball_tier = int(Global.player.call("get_orbiting_plasma_ball_count"))
	elif Global.player.has_method("has_orbiting_plasma_ball") and Global.player.call("has_orbiting_plasma_ball"):
		plasma_ball_tier = 1

	if plasma_ball_tier < 0:
		return 0
	if plasma_ball_tier > PLASMA_BALL_TIERS.size():
		return PLASMA_BALL_TIERS.size()
	return plasma_ball_tier

func _get_auto_grenade_cooldown() -> float:
	if auto_grenade_tier <= 0:
		return float(AUTO_GRENADE_TIERS[0]["cooldown"])

	var tier_index: int = int(clamp(auto_grenade_tier - 1, 0, AUTO_GRENADE_TIERS.size() - 1))
	return float(AUTO_GRENADE_TIERS[tier_index]["cooldown"])

func _get_auto_grenade_count() -> int:
	if auto_grenade_tier <= 0:
		return 0

	var tier_index: int = int(clamp(auto_grenade_tier - 1, 0, AUTO_GRENADE_TIERS.size() - 1))
	return int(AUTO_GRENADE_TIERS[tier_index]["grenades"])

func _on_auto_grenade_timer_timeout() -> void:
	if not _can_throw_auto_grenade():
		return

	_throw_auto_grenade_sequence(_get_auto_grenade_count())

func _can_throw_auto_grenade() -> bool:
	if not auto_grenade_active:
		return false
	if get_tree().paused:
		return false
	if survivor == null or not is_instance_valid(survivor):
		return false
	if survivor.get("is_dead") == true:
		return false

	return true

func _throw_auto_grenade_sequence(grenade_count: int) -> void:
	for grenade_index in range(grenade_count):
		if grenade_index > 0:
			await get_tree().create_timer(AUTO_GRENADE_SEQUENCE_DELAY, true).timeout

		if not _can_throw_auto_grenade():
			return

		var direction := _get_nearest_enemy_direction()
		if direction == Vector2.ZERO:
			return

		_throw_auto_grenade(direction, Vector2.ZERO)

func _throw_auto_grenade(direction: Vector2, lateral_offset: Vector2) -> void:
	var spawn_position := survivor.global_position + direction * AUTO_GRENADE_SPAWN_OFFSET + lateral_offset
	var pool_manager := _get_pool_manager()
	if pool_manager != null and pool_manager.has_method("spawn_grenade"):
		pool_manager.call(
			"spawn_grenade",
			spawn_position,
			direction,
			AUTO_GRENADE_THROW_FORCE,
			{"gravity_scale_override": 0.0}
		)
		return

	var grenade := AUTO_GRENADE_SCENE.instantiate() as RigidBody2D
	if grenade == null:
		return

	grenade.global_position = spawn_position
	grenade.set("gravity_scale_override", 0.0)
	get_tree().current_scene.add_child(grenade)

	if grenade.has_method("throw"):
		grenade.call("throw", direction, AUTO_GRENADE_THROW_FORCE)

func _get_nearest_enemy_direction() -> Vector2:
	var nearest_enemy: Node2D = null
	var nearest_distance_sq := INF

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == null or not is_instance_valid(enemy):
			continue

		var enemy_node := enemy as Node2D
		if enemy_node == null:
			continue

		var distance_sq := survivor.global_position.distance_squared_to(enemy_node.global_position)
		if distance_sq < nearest_distance_sq:
			nearest_enemy = enemy_node
			nearest_distance_sq = distance_sq

	if nearest_enemy == null:
		return Vector2.ZERO

	return (nearest_enemy.global_position - survivor.global_position).normalized()

func _on_shop_resume_pressed() -> void:
	if shop_layer and is_instance_valid(shop_layer):
		shop_layer.queue_free()
		shop_layer = null
	shop_offer_item_ids.clear()

	current_wave += 1
	get_tree().paused = false
	_start_current_wave()

func _get_pool_manager() -> Node:
	return get_tree().get_first_node_in_group("survival_pool_manager")

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

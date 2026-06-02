class_name WaveShop
extends CanvasLayer

signal purchase_requested(item_id: String)
signal resume_requested

const FEEDBACK_DEFAULT := "default"
const FEEDBACK_SUCCESS := "success"
const FEEDBACK_WARNING := "warning"
const FEEDBACK_ERROR := "error"

const ORANGE := Color(0.98, 0.33, 0.06, 1.0)
const GOLD := Color(1.0, 0.82, 0.06, 1.0)
const ICE := Color(0.78, 0.9, 0.96, 1.0)
const SUCCESS_GREEN := Color(0.55, 1.0, 0.72, 1.0)
const DISABLED_TEXT := Color(0.72, 0.78, 0.78, 1.0)

@onready var wave_title_label: Label = %WaveTitleLabel
@onready var cash_label: Label = %CashLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var resume_label: Label = %ResumeLabel
@onready var resume_touch: TouchScreenButton = %ResumeTouch

var item_nodes: Dictionary = {}

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_item_nodes()
	resume_touch.pressed.connect(_on_resume_pressed)

	for item_id in item_nodes:
		var touch := item_nodes[item_id]["touch"] as TouchScreenButton
		touch.pressed.connect(_on_purchase_pressed.bind(item_id))

func setup(current_wave: int, current_cash: int, item_states: Array[Dictionary]) -> void:
	_ensure_item_nodes()
	wave_title_label.text = "wave %d clear" % current_wave
	resume_label.text = "resume wave %d" % (current_wave + 1)
	_set_rows_visible(false)
	set_feedback("")
	refresh(current_cash, item_states)

func refresh(current_cash: int, item_states: Array[Dictionary]) -> void:
	_ensure_item_nodes()
	cash_label.text = "cash %s" % GameManager.format_cash(current_cash)

	for item_state in item_states:
		var item_id := String(item_state.get("id", ""))
		if not item_nodes.has(item_id):
			continue

		var nodes := item_nodes[item_id] as Dictionary
		var row := nodes["row"] as Control
		var title_label := nodes["title"] as Label
		var badge_label := nodes["badge"] as Label
		var description_label := nodes["description"] as Label
		var action_label := nodes["action"] as Label
		var button_root := nodes["button_root"] as Control
		var can_afford: bool = item_state.get("can_afford", false) == true
		var has_effect: bool = item_state.get("has_effect", true) == true

		row.visible = true
		title_label.text = String(item_state.get("title", ""))
		badge_label.text = String(item_state.get("badge", ""))
		description_label.text = String(item_state.get("description", ""))
		action_label.text = String(item_state.get("action_text", "buy"))
		action_label.add_theme_color_override("font_color", _get_action_color(item_state))
		button_root.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_afford and has_effect else Color(0.62, 0.62, 0.62, 0.82)

func set_feedback(message: String, feedback_type: String = FEEDBACK_DEFAULT) -> void:
	if feedback_label and is_instance_valid(feedback_label):
		feedback_label.text = message
		feedback_label.add_theme_color_override("font_color", _get_feedback_color(feedback_type))

func _cache_item_nodes() -> void:
	item_nodes = {
		"repair": _make_item_node_set(
			%RepairShopRow,
			%RepairTitle,
			%RepairBadgeLabel,
			%RepairDescription,
			%RepairPurchaseButton,
			%RepairActionLabel,
			%RepairPurchaseTouch
		),
		"overclock": _make_item_node_set(
			%OverclockShopRow,
			%OverclockTitle,
			%OverclockBadgeLabel,
			%OverclockDescription,
			%OverclockPurchaseButton,
			%OverclockActionLabel,
			%OverclockPurchaseTouch
		),
		"second_gun": _make_item_node_set(
			%SecondGunShopRow,
			%SecondGunTitle,
			%SecondGunBadgeLabel,
			%SecondGunDescription,
			%SecondGunPurchaseButton,
			%SecondGunActionLabel,
			%SecondGunPurchaseTouch
		),
		"shotgun": _make_item_node_set(
			%ShotgunShopRow,
			%ShotgunTitle,
			%ShotgunBadgeLabel,
			%ShotgunDescription,
			%ShotgunPurchaseButton,
			%ShotgunActionLabel,
			%ShotgunPurchaseTouch
		),
		"laser_sniper": _make_item_node_set(
			%LaserSniperShopRow,
			%LaserSniperTitle,
			%LaserSniperBadgeLabel,
			%LaserSniperDescription,
			%LaserSniperPurchaseButton,
			%LaserSniperActionLabel,
			%LaserSniperPurchaseTouch
		),
		"plasma_ball": _make_item_node_set(
			%LifeShopRow,
			%LifeTitle,
			%LifeBadgeLabel,
			%LifeDescription,
			%LifePurchaseButton,
			%LifeActionLabel,
			%LifePurchaseTouch
		),
		"auto_grenade": _make_item_node_set(
			%AutoGrenadeShopRow,
			%AutoGrenadeTitle,
			%AutoGrenadeBadgeLabel,
			%AutoGrenadeDescription,
			%AutoGrenadePurchaseButton,
			%AutoGrenadeActionLabel,
			%AutoGrenadePurchaseTouch
		)
	}

func _make_item_node_set(
	row: Control,
	title: Label,
	badge: Label,
	description: Label,
	button_root: Control,
	action: Label,
	touch: TouchScreenButton
) -> Dictionary:
	return {
		"row": row,
		"title": title,
		"badge": badge,
		"description": description,
		"button_root": button_root,
		"action": action,
		"touch": touch
	}

func _ensure_item_nodes() -> void:
	if item_nodes.is_empty():
		_cache_item_nodes()

func _set_rows_visible(is_visible: bool) -> void:
	for item_id in item_nodes:
		var row := item_nodes[item_id]["row"] as Control
		row.visible = is_visible

func _get_action_color(item_state: Dictionary) -> Color:
	if String(item_state.get("action_state", "")) in ["max", "equipped"]:
		return ICE

	if item_state.get("can_afford", false) == true and item_state.get("has_effect", true) == true:
		return ORANGE

	return DISABLED_TEXT

func _get_feedback_color(feedback_type: String) -> Color:
	match feedback_type:
		FEEDBACK_SUCCESS:
			return SUCCESS_GREEN
		FEEDBACK_WARNING:
			return GOLD
		FEEDBACK_ERROR:
			return ORANGE
		_:
			return ICE

func _on_purchase_pressed(item_id: String) -> void:
	purchase_requested.emit(item_id)

func _on_resume_pressed() -> void:
	resume_requested.emit()

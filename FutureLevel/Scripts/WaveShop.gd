class_name WaveShop
extends CanvasLayer

signal purchase_requested(item_id: String)
signal resume_requested
signal refresh_requested

const FEEDBACK_DEFAULT := "default"
const FEEDBACK_SUCCESS := "success"
const FEEDBACK_WARNING := "warning"
const FEEDBACK_ERROR := "error"

const ORANGE := Color(0.98, 0.33, 0.06, 1.0)
const GOLD := Color(1.0, 0.82, 0.06, 1.0)
const ICE := Color(0.78, 0.9, 0.96, 1.0)
const SUCCESS_GREEN := Color(0.55, 1.0, 0.72, 1.0)
const DISABLED_TEXT := Color(0.72, 0.78, 0.78, 1.0)
const OFFER_COUNT := 4
const BASE_CONTENT_WIDTH := 760.0
const PANEL_EDGE_PADDING_MIN := 4.0
const PANEL_EDGE_PADDING_MAX := 18.0
const SHOP_ROW_MAX_HEIGHT := 132.0
const SHOP_ROW_MIN_HEIGHT := 42.0
const SHOP_ICON_SCALE_MULTIPLIER := 1.08
const PURCHASE_BUTTON_BASE_SIZE := Vector2(280.0, 104.0)
const PURCHASE_BUTTON_TEXTURE_POSITION := Vector2(35.0, 4.0)
const PURCHASE_BUTTON_TEXTURE_SCALE := Vector2(0.21, 0.32)
const REFRESH_BUTTON_BASE_SIZE := Vector2(220.0, 84.0)
const REFRESH_BUTTON_TEXTURE_POSITION := Vector2(15.0, 7.0)
const REFRESH_BUTTON_TEXTURE_SCALE := Vector2(0.19, 0.24)
const RESUME_BUTTON_BASE_SIZE := Vector2(460.0, 116.0)
const RESUME_BUTTON_TEXTURE_POSITION := Vector2(50.0, 10.0)
const RESUME_BUTTON_TEXTURE_SCALE := Vector2(0.36, 0.31)

@onready var shop_panel: Control = $ShopRoot/ShopPanel
@onready var margins: MarginContainer = $ShopRoot/ShopPanel/Margins
@onready var content: VBoxContainer = $ShopRoot/ShopPanel/Margins/Content
@onready var header: HBoxContainer = $ShopRoot/ShopPanel/Margins/Content/Header
@onready var title_stack: VBoxContainer = $ShopRoot/ShopPanel/Margins/Content/Header/TitleStack
@onready var wave_title_label: Label = %WaveTitleLabel
@onready var subtitle_label: Label = $ShopRoot/ShopPanel/Margins/Content/Header/TitleStack/SubtitleLabel
@onready var cash_panel: Control = $ShopRoot/ShopPanel/Margins/Content/Header/CashPanel
@onready var cash_label: Label = %CashLabel
@onready var separator: ColorRect = $ShopRoot/ShopPanel/Margins/Content/Separator
@onready var item_list: VBoxContainer = $ShopRoot/ShopPanel/Margins/Content/ItemList
@onready var feedback_label: Label = %FeedbackLabel
@onready var resume_label: Label = %ResumeLabel
@onready var resume_button: Control = $ShopRoot/ShopPanel/Margins/Content/ResumeCenter/ResumeButton
@onready var resume_touch: TouchScreenButton = %ResumeTouch
@onready var refresh_button: Control = $ShopRoot/ShopPanel/Margins/Content/Header/RefreshButton
@onready var refresh_label: Label = %RefreshLabel
@onready var refresh_touch: TouchScreenButton = %RefreshTouch

var item_nodes: Dictionary = {}

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_item_nodes()
	_connect_viewport_resize()
	_apply_responsive_layout()
	resume_touch.pressed.connect(_on_resume_pressed)
	refresh_touch.pressed.connect(_on_refresh_pressed)

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
	_set_rows_visible(false)

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

	_apply_responsive_layout()

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

func _connect_viewport_resize() -> void:
	var viewport := get_viewport()
	if viewport and not viewport.size_changed.is_connected(_apply_responsive_layout):
		viewport.size_changed.connect(_apply_responsive_layout)

func _apply_responsive_layout() -> void:
	if not is_node_ready() or item_nodes.is_empty():
		return

	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var safe_area := _get_safe_area_in_viewport(viewport_size)
	var edge_padding: float = clamp(
		min(safe_area.size.x, safe_area.size.y) * 0.016,
		PANEL_EDGE_PADDING_MIN,
		PANEL_EDGE_PADDING_MAX
	)
	edge_padding = min(edge_padding, safe_area.size.x * 0.04, safe_area.size.y * 0.04)
	_apply_safe_panel_offsets(viewport_size, safe_area, edge_padding)

	var panel_size := Vector2(
		max(1.0, safe_area.size.x - edge_padding * 2.0),
		max(1.0, safe_area.size.y - edge_padding * 2.0)
	)
	var inner_margin_x := _responsive_int(panel_size.x * 0.035, 8, 56)
	var inner_margin_y := _responsive_int(panel_size.y * 0.024, 4, 48)
	if panel_size.y < 520.0:
		inner_margin_y = _responsive_int(panel_size.y * 0.018, 3, 14)

	_set_margin_constants(margins, inner_margin_x, inner_margin_y, inner_margin_x, inner_margin_y)

	var content_width: float = max(1.0, panel_size.x - float(inner_margin_x * 2))
	var content_height: float = max(1.0, panel_size.y - float(inner_margin_y * 2))
	var is_short_screen := panel_size.y < 520.0
	var height_budget: float = max(1.0, content_height - (18.0 if is_short_screen else 8.0))
	var content_separation := _responsive_int(height_budget * (0.009 if is_short_screen else 0.012), 2 if is_short_screen else 3, 16)
	var item_separation := _responsive_int(height_budget * (0.008 if is_short_screen else 0.010), 2 if is_short_screen else 3, 14)
	var separator_height := _responsive_int(height_budget * 0.004, 1, 3)
	var header_height: float = clamp(height_budget * (0.085 if is_short_screen else 0.10), 34.0 if is_short_screen else 44.0, 110.0)
	var feedback_height: float = clamp(height_budget * (0.025 if is_short_screen else 0.030), 10.0 if is_short_screen else 12.0, 26.0)
	var resume_height: float = clamp(height_budget * (0.078 if is_short_screen else 0.085), 36.0 if is_short_screen else 42.0, 116.0)
	var reserved_height: float = (
		header_height
		+ float(separator_height)
		+ feedback_height
		+ resume_height
		+ float(content_separation * 4)
		+ float(item_separation * (OFFER_COUNT - 1))
	)
	var row_height: float = (height_budget - reserved_height) / float(OFFER_COUNT)
	row_height = clamp(row_height, SHOP_ROW_MIN_HEIGHT, SHOP_ROW_MAX_HEIGHT)

	var width_scale: float = clamp(content_width / BASE_CONTENT_WIDTH, 0.42, 1.0)
	var height_scale: float = clamp(row_height / SHOP_ROW_MAX_HEIGHT, 0.42, 1.0)
	var layout_scale: float = min(width_scale, height_scale)

	content.add_theme_constant_override("separation", content_separation)
	item_list.add_theme_constant_override("separation", item_separation)
	separator.custom_minimum_size = Vector2(0.0, float(separator_height))
	feedback_label.custom_minimum_size = Vector2(0.0, feedback_height)
	feedback_label.add_theme_font_size_override("font_size", _scaled_font(16, layout_scale, 9))

	_apply_header_layout(content_width, header_height, layout_scale, is_short_screen)
	_apply_offer_layout(content_width, row_height, layout_scale)
	_apply_resume_layout(content_width, resume_height, layout_scale)

func _apply_header_layout(content_width: float, header_height: float, layout_scale: float, is_short_screen: bool) -> void:
	header.custom_minimum_size = Vector2(0.0, header_height)
	header.add_theme_constant_override("separation", _scaled_int(22, layout_scale, 4))
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override("separation", 0)

	var cash_size := Vector2(
		clamp(content_width * 0.30, 86.0, 300.0),
		clamp(header_height * 0.76, 30.0, 84.0)
	)
	var refresh_size := Vector2(
		clamp(content_width * 0.25, 76.0, 220.0),
		clamp(header_height * 0.76, 30.0, 84.0)
	)
	cash_panel.custom_minimum_size = cash_size
	_configure_button(
		refresh_button,
		refresh_touch,
		refresh_label,
		refresh_size,
		REFRESH_BUTTON_BASE_SIZE,
		REFRESH_BUTTON_TEXTURE_POSITION,
		REFRESH_BUTTON_TEXTURE_SCALE,
		_scaled_font(22, layout_scale, 11)
	)

	wave_title_label.clip_text = true
	subtitle_label.visible = not is_short_screen
	subtitle_label.clip_text = true
	cash_label.clip_text = true
	var title_font_size := _scaled_font(44, layout_scale, 16)
	if is_short_screen:
		title_font_size = min(title_font_size, 16)
	wave_title_label.add_theme_font_size_override("font_size", title_font_size)
	subtitle_label.add_theme_font_size_override("font_size", _scaled_font(22, layout_scale, 9))
	cash_label.add_theme_font_size_override("font_size", _scaled_font(24, layout_scale, 11))

func _apply_offer_layout(content_width: float, row_height: float, layout_scale: float) -> void:
	for item_id in item_nodes:
		var nodes := item_nodes[item_id] as Dictionary
		var row := nodes["row"] as Control
		var title_label := nodes["title"] as Label
		var badge_label := nodes["badge"] as Label
		var description_label := nodes["description"] as Label
		var button_root := nodes["button_root"] as Control
		var action_label := nodes["action"] as Label
		var touch := nodes["touch"] as TouchScreenButton
		var row_margins := row.get_node("Margins") as MarginContainer
		var row_box := row_margins.get_node("Row") as HBoxContainer
		var badge_panel := row_box.get_node("Badge") as Control

		row.custom_minimum_size = Vector2(0.0, row_height)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_box.add_theme_constant_override("separation", _scaled_int(14, layout_scale, 4))

		var row_margin_x := _scaled_int(18, layout_scale, 4)
		var row_margin_y := _responsive_int(row_height * 0.08, 2, 9)
		_set_margin_constants(row_margins, row_margin_x, row_margin_y, row_margin_x, row_margin_y)
		var badge_size: float = clamp(
			row_height - float(row_margin_y * 2),
			30.0,
			_scaled_float(62.0, layout_scale, 62.0, 36.0)
		)
		badge_panel.custom_minimum_size = Vector2(badge_size, badge_size)
		_scale_badge_icons(badge_panel, SHOP_ICON_SCALE_MULTIPLIER)

		var purchase_size := Vector2(
			clamp(content_width * 0.31, 74.0, PURCHASE_BUTTON_BASE_SIZE.x),
			clamp(row_height * 0.78, 34.0, PURCHASE_BUTTON_BASE_SIZE.y)
		)
		_configure_button(
			button_root,
			touch,
			action_label,
			purchase_size,
			PURCHASE_BUTTON_BASE_SIZE,
			PURCHASE_BUTTON_TEXTURE_POSITION,
			PURCHASE_BUTTON_TEXTURE_SCALE,
			_scaled_font(24, layout_scale, 11)
		)

		title_label.clip_text = true
		description_label.clip_text = true
		badge_label.clip_text = true
		title_label.add_theme_font_size_override("font_size", _scaled_font(26, layout_scale, 13))
		description_label.add_theme_font_size_override("font_size", _scaled_font(14, layout_scale, 8))
		badge_label.add_theme_font_size_override("font_size", _scaled_font(20, layout_scale, 9))

func _apply_resume_layout(content_width: float, resume_height: float, layout_scale: float) -> void:
	var resume_size := Vector2(
		clamp(content_width * 0.76, 150.0, RESUME_BUTTON_BASE_SIZE.x),
		resume_height
	)
	_configure_button(
		resume_button,
		resume_touch,
		resume_label,
		resume_size,
		RESUME_BUTTON_BASE_SIZE,
		RESUME_BUTTON_TEXTURE_POSITION,
		RESUME_BUTTON_TEXTURE_SCALE,
		_scaled_font(30, layout_scale, 14)
	)
	resume_label.clip_text = true

func _configure_button(
	button_root: Control,
	touch: TouchScreenButton,
	label: Label,
	minimum_size: Vector2,
	base_size: Vector2,
	touch_position: Vector2,
	touch_scale: Vector2,
	font_size: int
) -> void:
	button_root.custom_minimum_size = minimum_size
	var ratio := Vector2(minimum_size.x / base_size.x, minimum_size.y / base_size.y)
	touch.position = Vector2(touch_position.x * ratio.x, touch_position.y * ratio.y)
	touch.scale = Vector2(touch_scale.x * ratio.x, touch_scale.y * ratio.y)
	var horizontal_padding: float = max(3.0, minimum_size.x * 0.08)
	label.offset_left = horizontal_padding
	label.offset_right = -horizontal_padding
	label.offset_top = max(1.0, minimum_size.y * 0.07)
	label.offset_bottom = -max(2.0, minimum_size.y * 0.13)
	label.add_theme_font_size_override("font_size", font_size)

func _scale_badge_icons(root: Node, scale_multiplier: float) -> void:
	for child in root.get_children():
		var sprite := child as Sprite2D
		if sprite:
			if not sprite.has_meta("shop_base_scale"):
				sprite.set_meta("shop_base_scale", sprite.scale)
			var base_scale = sprite.get_meta("shop_base_scale")
			if base_scale is Vector2:
				sprite.scale = base_scale * scale_multiplier

		_scale_badge_icons(child, scale_multiplier)

func _get_safe_area_in_viewport(viewport_size: Vector2) -> Rect2:
	var fallback := Rect2(Vector2.ZERO, viewport_size)
	var window_size_i := DisplayServer.window_get_size()
	if window_size_i.x <= 0 or window_size_i.y <= 0:
		return fallback

	var safe_pixels := DisplayServer.get_display_safe_area()
	if safe_pixels.size.x <= 0 or safe_pixels.size.y <= 0:
		return fallback

	if (
		safe_pixels.position.x < 0
		or safe_pixels.position.y < 0
		or safe_pixels.position.x + safe_pixels.size.x > window_size_i.x + 2
		or safe_pixels.position.y + safe_pixels.size.y > window_size_i.y + 2
	):
		return fallback

	var window_size := Vector2(float(window_size_i.x), float(window_size_i.y))
	var left := float(safe_pixels.position.x) / window_size.x * viewport_size.x
	var top := float(safe_pixels.position.y) / window_size.y * viewport_size.y
	var right := float(window_size_i.x - safe_pixels.position.x - safe_pixels.size.x) / window_size.x * viewport_size.x
	var bottom := float(window_size_i.y - safe_pixels.position.y - safe_pixels.size.y) / window_size.y * viewport_size.y
	return Rect2(
		Vector2(left, top),
		Vector2(
			max(1.0, viewport_size.x - left - right),
			max(1.0, viewport_size.y - top - bottom)
		)
	)

func _apply_safe_panel_offsets(viewport_size: Vector2, safe_area: Rect2, padding: float) -> void:
	shop_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_panel.offset_left = safe_area.position.x + padding
	shop_panel.offset_top = safe_area.position.y + padding
	shop_panel.offset_right = -(viewport_size.x - safe_area.end.x + padding)
	shop_panel.offset_bottom = -(viewport_size.y - safe_area.end.y + padding)

func _set_margin_constants(container: MarginContainer, left: int, top: int, right: int, bottom: int) -> void:
	container.add_theme_constant_override("margin_left", left)
	container.add_theme_constant_override("margin_top", top)
	container.add_theme_constant_override("margin_right", right)
	container.add_theme_constant_override("margin_bottom", bottom)

func _responsive_int(value: float, minimum: int, maximum: int) -> int:
	return int(round(clamp(value, float(minimum), float(maximum))))

func _scaled_int(base_value: int, scale: float, minimum: int) -> int:
	return int(round(clamp(float(base_value) * scale, float(minimum), float(base_value))))

func _scaled_float(base_value: float, scale: float, maximum: float, minimum: float) -> float:
	return clamp(base_value * scale, minimum, maximum)

func _scaled_font(base_size: int, scale: float, minimum: int) -> int:
	return int(round(clamp(float(base_size) * scale, float(minimum), float(base_size))))

func _ensure_item_nodes() -> void:
	if item_nodes.is_empty():
		_cache_item_nodes()
		_apply_responsive_layout()

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

func _on_refresh_pressed() -> void:
	refresh_requested.emit()

func _on_resume_pressed() -> void:
	resume_requested.emit()

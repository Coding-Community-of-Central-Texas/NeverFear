extends Control


@onready var settings_popup: PopupPanel = $SettingsPopup
@onready var resolution_option: OptionButton = $SettingsPopup/ResolutionOption
@onready var stretch_factor_option: OptionButton = $SettingsPopup/StretchFactorOption
@onready var stretch_aspect_option: OptionButton = $SettingsPopup/StretchAspectOption
@onready var scale_factor_value: LineEdit = $SettingsPopup/ScaleFactorValue
@onready var scale_factor_slider: HSlider = $SettingsPopup/ScaleFactorSlider


var base_window_size = Vector2()
var stretch_mode = Window.CONTENT_SCALE_MODE_DISABLED
var stretch_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
var scale_factor = 1.0


func _ready():
	load_settings()
	apply_best_resolution()
	setup_ui()
	update_ui()

func apply_best_resolution():
	var screen_size = DisplayServer.window_get_size_with_decorations()
	if screen_size.x >= 1680 and screen_size.y >= 720:
		base_window_size = Vector2(1680, 720)
	elif screen_size.x >= 1280 and screen_size.y >= 800:
		base_window_size = Vector2(1280, 800)
	elif screen_size.x >= 1280 and screen_size.y >= 720:
		base_window_size = Vector2(1280, 720)
	elif screen_size.x >= 1152 and screen_size.y >= 648:
		base_window_size = Vector2(1152, 648)
	elif screen_size.x >= 800 and screen_size.y >= 600:
		base_window_size = Vector2(800, 600)
	elif screen_size.x >= 720 and screen_size.y >= 480:
		base_window_size = Vector2(720, 480)
	elif screen_size.x >= 640 and screen_size.y >= 480:
		base_window_size = Vector2(640, 480)
	else:
		base_window_size = Vector2(648, 648)
	
	get_window().set_size(base_window_size)

func setup_ui():
	settings_popup.hide()  # Ensure it starts hidden

	var vbox = VBoxContainer.new()
	settings_popup.add_child(vbox)

	var resolution_label = Label.new()
	resolution_label.text = "Resolution"
	vbox.add_child(resolution_label)

	resolution_option = OptionButton.new()
	resolution_option.name = "ResolutionOptionButton"
	resolution_option.add_item("648×648 (1:1)", 0)
	resolution_option.add_item("640×480 (4:3)", 1)
	resolution_option.add_item("720×480 (3:2)", 2)
	resolution_option.add_item("800×600 (4:3)", 3)
	resolution_option.add_item("1152×648 (16:9)", 4)
	resolution_option.add_item("1280×720 (16:9)", 5)
	resolution_option.add_item("1280×800 (16:10)", 6)
	resolution_option.add_item("1680×720 (21:9)", 7)
	resolution_option.connect("item_selected", Callable(self, "on_window_base_size_item_selected"))
	vbox.add_child(resolution_option)

	var close_button = Button.new()
	close_button.text = "Close"
	close_button.connect("pressed", Callable(self, "close_settings"))
	vbox.add_child(close_button)


	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 300)
	add_child(panel)


	var resolution_option = OptionButton.new()
	resolution_option.name = "ResolutionOption"
	resolution_option.add_item("648×648 (1:1)", 0)
	resolution_option.add_item("640×480 (4:3)", 1)
	resolution_option.add_item("720×480 (3:2)", 2)
	resolution_option.add_item("800×600 (4:3)", 3)
	resolution_option.add_item("1152×648 (16:9)", 4)
	resolution_option.add_item("1280×720 (16:9)", 5)
	resolution_option.add_item("1280×800 (16:10)", 6)
	resolution_option.add_item("1680×720 (21:9)", 7)
	resolution_option.connect("item_selected", Callable(self, "on_window_base_size_item_selected"))
	vbox.add_child(resolution_option)

	var stretch_mode_label = Label.new()
	stretch_mode_label.text = "Stretch Mode"
	vbox.add_child(stretch_mode_label)

	var stretch_mode_option = OptionButton.new()
	stretch_mode_option.name = "StretchModeOption"
	stretch_mode_option.add_item("Disabled", Window.CONTENT_SCALE_MODE_DISABLED)
	stretch_mode_option.add_item("2D", Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH)
	stretch_mode_option.add_item("Viewport", Window.CONTENT_SCALE_MODE_VIEWPORT)
	stretch_mode_option.connect("item_selected", Callable(self, "on_window_stretch_mode_item_selected"))
	vbox.add_child(stretch_mode_option)

	var stretch_aspect_label = Label.new()
	stretch_aspect_label.text = "Stretch Aspect"
	vbox.add_child(stretch_aspect_label)

	var stretch_aspect_option = OptionButton.new()
	stretch_aspect_option.name = "StretchAspectOption"
	stretch_aspect_option.add_item("Ignore", Window.CONTENT_SCALE_ASPECT_IGNORE)
	stretch_aspect_option.add_item("Keep", Window.CONTENT_SCALE_ASPECT_KEEP)
	stretch_aspect_option.add_item("Keep Width", Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH)
	stretch_aspect_option.add_item("Keep Height", Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT)
	stretch_aspect_option.connect("item_selected", Callable(self, "on_window_stretch_aspect_item_selected"))
	vbox.add_child(stretch_aspect_option)

	var scale_factor_label = Label.new()
	scale_factor_label.text = "Scale Factor"
	vbox.add_child(scale_factor_label)

	var scale_factor_slider = HSlider.new()
	scale_factor_slider.name = "ScaleFactorSlider"
	scale_factor_slider.min_value = 0.5
	scale_factor_slider.max_value = 2.0
	scale_factor_slider.step = 0.1
	scale_factor_slider.value = 1.0
	scale_factor_slider.connect("drag_ended", Callable(self, "on_window_scale_factor_drag_ended"))
	vbox.add_child(scale_factor_slider)

	var scale_factor_value = Label.new()
	scale_factor_value.name = "ScaleFactorValue"
	scale_factor_value.text = "100%"
	vbox.add_child(scale_factor_value)

	var credits_button = Button.new()
	credits_button.text = "Credits"
	credits_button.connect("pressed", Callable(self, "on_credits_pressed"))
	vbox.add_child(credits_button)

func update_ui():
	if $SettingsPopup/ResolutionOption:
		$SettingsPopup/ResolutionOption.selected_index = get_resolution_index(base_window_size)
	if $SettingsPopup/StrechModeOption:
		$SettingsPopup/StretchModeOption.selected_index = stretch_mode
	if $SettingsPopup/StretchAspectOption:
		$SettingsPopup/StretchAspectOption.selected_index = stretch_aspect
	if $SettingsPopup/ScaleFactorSlider:
		$SettingsPopup/ScaleFactorSlider.value = scale_factor
	if $SettingsPopup/ScaleFactorValue:
		$SettingsPopup/ScaleFactorValue.text = "%d%%" % (scale_factor * 100)


func get_resolution_index(size: Vector2) -> int:
	match size:
		Vector2(648, 648): return 0
		Vector2(640, 480): return 1
		Vector2(720, 480): return 2
		Vector2(800, 600): return 3
		Vector2(1152, 648): return 4
		Vector2(1280, 720): return 5
		Vector2(1280, 800): return 6
		Vector2(1680, 720): return 7
		_:
			return -1

func on_window_base_size_item_selected(index: int) -> void:
	var resolutions = [
		Vector2(648, 648), Vector2(640, 480), Vector2(720, 480), 
		Vector2(800, 600), Vector2(1152, 648), Vector2(1280, 720),
		Vector2(1280, 800), Vector2(1680, 720)
	]
	base_window_size = resolutions[index]
	get_window().set_size(base_window_size)
	save_settings()

func on_window_stretch_mode_item_selected(index: int) -> void:
	stretch_mode = index as Window.ContentScaleMode
	get_viewport().content_scale_mode = stretch_mode
	save_settings()

func on_window_stretch_aspect_item_selected(index: int) -> void:
	stretch_aspect = index as Window.ContentScaleAspect
	get_viewport().content_scale_aspect = stretch_aspect
	save_settings()

func on_window_scale_factor_drag_ended(_value_changed: bool) -> void:
	scale_factor = $"ScaleFactorSlider".value
	$"ScaleFactorValue".text = "%d%%" % (scale_factor * 100)
	get_viewport().content_scale_factor = scale_factor
	save_settings()

func on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Singletons/Displaysetting.tscn")

# Save user settings
func save_settings():
	var config = ConfigFile.new()
	config.set_value("display", "resolution", base_window_size)
	config.set_value("display", "stretch_mode", stretch_mode)
	config.set_value("display", "stretch_aspect", stretch_aspect)
	config.set_value("display", "scale_factor", scale_factor)
	config.save("user://settings.cfg")

# Load user settings
func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		base_window_size = config.get_value("display", "resolution", Vector2(1280, 720))
		stretch_mode = config.get_value("display", "stretch_mode", Window.CONTENT_SCALE_MODE_DISABLED)
		stretch_aspect = config.get_value("display", "stretch_aspect", Window.CONTENT_SCALE_ASPECT_IGNORE)
		scale_factor = config.get_value("display", "scale_factor", 1.0)

func show_settings():
	settings_popup.popup_centered(Vector2(500, 400))  # Opens the popup centered

func close_settings():
	settings_popup.hide()  # Closes the popup

extends Control

var base_window_size = Vector2()
var stretch_mode = Window.CONTENT_SCALE_MODE_DISABLED
var stretch_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
var scale_factor = 1.0

func _ready():
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
	
	get_viewport().content_scale_size = base_window_size

func setup_ui():
	var panel = Panel.new()
	panel.rect_min_size = Vector2(400, 300)
	add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var resolution_label = Label.new()
	resolution_label.text = "Resolution"
	vbox.add_child(resolution_label)

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
	resolution_option.connect("item_selected", Callable (self, "_on_window_base_size_item_selected"))
	vbox.add_child(resolution_option)

	var stretch_mode_label = Label.new()
	stretch_mode_label.text = "Stretch Mode"
	vbox.add_child(stretch_mode_label)

	var stretch_mode_option = OptionButton.new()
	stretch_mode_option.name = "StretchModeOption"
	stretch_mode_option.add_item("Disabled", Window.CONTENT_SCALE_MODE_DISABLED)
	stretch_mode_option.add_item("2D", Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH)
	stretch_mode_option.add_item("Viewport", Window.CONTENT_SCALE_MODE_VIEWPORT)
	stretch_mode_option.connect("item_selected", Callable (self, "_on_window_stretch_mode_item_selected"))
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
	stretch_aspect_option.connect("item_selected", Callable (self, "_on_window_stretch_aspect_item_selected"))
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
	scale_factor_slider.connect("drag_ended", Callable (self, "_on_window_scale_factor_drag_ended"))
	vbox.add_child(scale_factor_slider)

	var scale_factor_value = Label.new()
	scale_factor_value.name = "ScaleFactorValue"
	scale_factor_value.text = "100%"
	vbox.add_child(scale_factor_value)

	var credits_button = Button.new()
	credits_button.text = "Credits"
	credits_button.connect("pressed", Callable (self, "_on_credits_pressed"))
	vbox.add_child(credits_button)

func update_ui():
	$"ResolutionOption".selected = get_resolution_index(base_window_size)
	$"StretchModeOption".selected = stretch_mode
	$"StretchAspectOption".selected = stretch_aspect
	$"ScaleFactorSlider".value = scale_factor
	$"ScaleFactorValue".text = "%d%%" % (scale_factor * 100)

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

func _on_window_base_size_item_selected(index: int) -> void:
	match index:
		0:  # 648×648 (1:1)
			base_window_size = Vector2(648, 648)
		1:  # 640×480 (4:3)
			base_window_size = Vector2(640, 480)
		2:  # 720×480 (3:2)
			base_window_size = Vector2(720, 480)
		3:  # 800×600 (4:3)
			base_window_size = Vector2(800, 600)
		4:  # 1152×648 (16:9)
			base_window_size = Vector2(1152, 648)
		5:  # 1280×720 (16:9)
			base_window_size = Vector2(1280, 720)
		6:  # 1280×800 (16:10)
			base_window_size = Vector2(1280, 800)
		7:  # 1680×720 (21:9)
			base_window_size = Vector2(1680, 720)

	get_viewport().content_scale_size = base_window_size

func _on_window_stretch_mode_item_selected(index: int) -> void:
	stretch_mode = index as Window.ContentScaleMode
	get_viewport().content_scale_mode = stretch_mode

	# Disable irrelevant options when the stretch mode is Disabled.
	$"ResolutionOption".disabled = stretch_mode == Window.CONTENT_SCALE_MODE_DISABLED
	$"StretchAspectOption".disabled = stretch_mode == Window.CONTENT_SCALE_MODE_DISABLED

func _on_window_stretch_aspect_item_selected(index: int) -> void:
	stretch_aspect = index as Window.ContentScaleAspect
	get_viewport().content_scale_aspect = stretch_aspect

func _on_window_scale_factor_drag_ended(_value_changed: bool) -> void:
	scale_factor = $"ScaleFactorSlider".value
	$"ScaleFactorValue".text = "%d%%" % (scale_factor * 100)
	get_viewport().content_scale_factor = scale_factor

func _on_window_stretch_scale_mode_item_selected(index: int) -> void:
	get_viewport().content_scale_stretch = index

func _on_credits_pressed() -> void:
	get_tree().change_scene_to("res://Singletons/Displaysetting.tscn")

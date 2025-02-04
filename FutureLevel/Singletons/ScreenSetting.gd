extends Node

# Define target aspect ratios for landscape & portrait
const LANDSCAPE_ASPECT = Vector2(16, 9)  # Example: 1920x1080
const PORTRAIT_ASPECT = Vector2(9, 16)   # Example: 1080x1920

func _ready():
	get_viewport().connect("size_changed", Callable(self, "_on_window_size_changed"))
	_on_window_size_changed()  # Apply initial settings

func _on_window_size_changed():
	var screen_size = get_viewport().get_visible_rect().size
	var is_landscape = screen_size.x > screen_size.y

	var target_resolution = LANDSCAPE_ASPECT if is_landscape else PORTRAIT_ASPECT
	var target_width = screen_size.x
	var target_height = (target_width / target_resolution.x) * target_resolution.y

	if target_height > screen_size.y:
		target_height = screen_size.y
		target_width = (target_height / target_resolution.y) * target_resolution.x

	# Adjust scale factor to prevent zoom-out issues
	var scale_factor = min(screen_size.x / target_width, screen_size.y / target_height)
	get_viewport().content_scale_factor = scale_factor

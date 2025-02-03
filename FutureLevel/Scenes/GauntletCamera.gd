extends Camera2D

@export var landscape_zoom: Vector2 = Vector2(1.15, 1.15)
@export var portrait_zoom: Vector2 = Vector2(1.5, 1.15)

func _ready():
	adjust_camera(get_viewport().size)

func _process(_delta):
	var new_size = get_viewport().size
	adjust_camera(new_size)

func adjust_camera(viewport_size: Vector2):
	if viewport_size.x > viewport_size.y:
		# Landscape Mode
		zoom = landscape_zoom
	else:
		# Portrait Mode
		zoom = portrait_zoom

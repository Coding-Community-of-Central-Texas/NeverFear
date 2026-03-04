extends CanvasLayer

@onready var special: TouchScreenButton = $special
@onready var timer: Timer = $Timer
@onready var specialholder: Sprite2D = $Specialholder

@export var cooldown_seconds: float = 2.0

func _on_special_released() -> void:
	grenade_cooldown()

func grenade_cooldown() -> void:
	special.visible = false
	specialholder.visible = true       
	timer.start(max(0.01, cooldown_seconds))

func _on_timer_timeout() -> void:
	special.visible = true
	specialholder.visible = false

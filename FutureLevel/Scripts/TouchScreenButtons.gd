extends Node2D  # Replace with your parent node

@onready var right: TouchScreenButton = $Right
@onready var left: TouchScreenButton = $Left
@onready var leftsprite: AnimatedSprite2D = $Left/AnimatedSprite2D
@onready var rightsprite: AnimatedSprite2D = $Right/AnimatedSprite2D


func _ready():
	# Connect button signals to their respective functions
	left.connect("pressed", Callable(self, "_on_left_button_pressed"))
	right.connect("pressed", Callable(self, "_on_right_button_pressed"))

func _on_left_button_pressed():
	# Play the "left" animation
	leftsprite.play("left")

func _on_right_button_pressed():
	# Play the "right" animation
	rightsprite.play("right")

func _on_left_button_released():
	leftsprite.stop()

func _on_right_button_released():
	rightsprite.stop()

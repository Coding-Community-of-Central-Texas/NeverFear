extends TouchScreenButton

@onready var jump: TouchScreenButton = self
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D



func _ready():
	# Connect button signals to their respective functions
	jump.connect("pressed", Callable(self, "_on_jump_button_pressed"))

func _on_jump_button_pressed():
	# Play the "left" animation
	animated_sprite_2d.play("jump")


func _on_jump_button_released():
	animated_sprite_2d.stop()
	animated_sprite_2d.frame = 0 

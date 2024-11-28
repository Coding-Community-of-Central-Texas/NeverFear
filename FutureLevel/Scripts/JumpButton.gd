extends TouchScreenButton


func _ready() -> void:
	%AnimationPlayer.play("static")
	
func _on_pressed() -> void:
	%AnimationPlayer.play("jump")


func _on_released() -> void:
	%AnimationPlayer.play("static")

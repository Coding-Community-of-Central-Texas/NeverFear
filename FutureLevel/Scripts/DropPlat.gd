extends AnimatableBody2D

signal reset

@onready var timer: Timer = $Timer
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D

# Called when the node enters the scene tree for the first time.

func _reset():
	if Global.player._respawn():
		emit_signal("reset")

func _ready() -> void:
	%AnimationPlayer.play("start")
	%CollisionShape2D.disabled = false
	



func _on_reset() -> void:
	%AnimationPlayer.play("start")
	collision_shape_2d.disabled = false

extends Area2D

var health = 50 
@onready var marker_2d: Marker2D = $Marker2D



func _on_ready():
	%AnimationPlayer.play("RESET")


func take_damage():
	health -= 15
	const BOOM = preload("res://Scenes/Boom.tscn")
	var new_Boom = BOOM.instantiate()
	new_Boom.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", new_Boom)
	if health <= 0:
		die()

func animation():
	if take_damage():
		%Animation.play("hurt")

func die():
	%AnimationPlayer.play("die")
	const BOOM = preload("res://Scenes/Boom.tscn")
	var new_Boom = BOOM.instantiate()
	new_Boom.global_position = marker_2d
	get_tree().current_scene.call_deferred("add_child", new_Boom)
	

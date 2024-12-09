extends Node2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D



const BOSS = preload("res://Scenes/FinalBoss.tscn")




func _on_body_entered(body):
	if body.is_in_group("player"): 
		audio_stream_player_2d.play()
		var character_to_spawn = BOSS
		var character_instance = character_to_spawn.instantiate()
		get_tree().current_scene.call_deferred("add_child", character_instance)
		
		 # Position the character at the Area2D's location (or adjust as needed)
		character_instance.position = position


func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		queue_free()

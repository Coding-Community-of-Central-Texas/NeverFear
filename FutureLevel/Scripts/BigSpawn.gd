extends Node2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D



const ROBBIE = preload("res://Scenes/ThreeHitter.tscn")
const TANK = preload("res://Scenes/TankLegacy.tscn")

enum Big {
	ROBBIE,
	TANK
}


func _on_body_entered(body):
	if body.is_in_group("player"):  # Ensure the body is part of the player group
		var character_to_spawn: PackedScene
		if randi() % 2 == 0:  # Randomly select between ROBBIE and TANK
			character_to_spawn = ROBBIE
		else:
			character_to_spawn = TANK
				
		# Instance the selected character and add it to the scene
		var character_instance = character_to_spawn.instantiate()
		get_tree().current_scene.call_deferred("add_child", character_instance)
		
		 # Position the character at the Area2D's location (or adjust as needed)
		character_instance.position = position

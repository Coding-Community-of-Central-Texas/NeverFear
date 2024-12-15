extends Marker2D

const ROBBIE = preload("res://Scenes/GauntletThreeHitter.tscn")
const TANK = preload("res://Scenes/TankGauntlet.tscn")

enum CharacterType {
	ROBBIE,
	TANK
}


@onready var timer: Timer = $Timer
@onready var marker_1: Marker2D = $Marker1


func _on_timer_timeout() -> void:
	spawn_wave()

func spawn_wave():
	# Randomly select the characters to spawn
	var spawn_list = [
		get_random_character(CharacterType.ROBBIE, CharacterType.TANK)
	]
	# Iterate through the spawn list and spawn characters
	for character in spawn_list:  
		var instance = character.instantiate()
		instance.position = marker_1.global_position  
		get_tree().current_scene.add_child(instance)
		# Optional: Adjust spacing if needed

func get_random_character(_type1: int, _type2: int) -> PackedScene:
	return ROBBIE if randi() % 2 == 0 else TANK 

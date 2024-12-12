extends Path2D

const ROBBIE = preload("res://Scenes/GauntletThreeHitter.tscn")
const TANK = preload("res://Scenes/TankGauntlet.tscn")


enum CharacterType {
	ROBBIE,
	TANK
}

@onready var big_timer: Timer = $BigTimer

func _ready() -> void:
	big_timer.start()

func _on_timer_timeout() -> void:
	spawn_wave()

func spawn_wave():
	# Randomly select the characters to spawn
	var spawn_list = [
		get_random_character(CharacterType.ROBBIE, CharacterType.TANK)
	]
	# Iterate through the spawn list and spawn characters
	for character in spawn_list:
		%PathFollow2D.progress_ratio = randf()  
		var instance = character.instantiate()
		instance.position = %PathFollow2D.position  
		get_tree().current_scene.add_child(instance)
		# Optional: Adjust spacing if needed
		%PathFollow2D.progress_ratio += 0.1
		if %PathFollow2D.progress_ratio > 1.0:
			%PathFollow2D.progress_ratio -= 1.0

func get_random_character(_type1: int, _type2: int) -> PackedScene:
	return ROBBIE if randi() % 2 == 0 else TANK 

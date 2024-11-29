extends Node2D


func _on_hero_health_depleated() -> void:
	%GameOver.visible = true 



func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
	

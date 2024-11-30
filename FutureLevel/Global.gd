extends Node

var player = "res://Scenes/Hero.tscn"

var lives: int = 3  
var checkpoint_position: Vector2 = Vector2(220.996, -193.005)

var money: int = 0
var past_money: int = 0
var most_money: int = 0
var kills: int = 0

func reset_game_state():
	checkpoint_position = Vector2(220.996, -193.005) # Starting position
	lives = 3  # Reset lives to the initial value
	Engine.time_scale = 1.0

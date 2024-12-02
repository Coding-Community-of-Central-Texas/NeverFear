extends CharacterBody2D

@onready var weak_point_1: Area2D = $WeakPoint1
@onready var weak_point_2: Area2D = $WeakPoint2
@onready var weak_point_3: Area2D = $WeakPoint3
@onready var weak_point_4: Area2D = $WeakPoint4
@onready var health_bar: ProgressBar = $CanvasLayer/HealthBar

var health = 400


func _ready() -> void:
	%BossRobo.play("walk")

	%AnimationPlayer.play("protect")

func take_damage():
	health -= 30
	%AnimationPlayer.play("hurt")
	%BossRobo.play("Attack")
	health_bar.health = health
	if health <= 0:
		die()

func weak_point():
	if weak_point_1.die():
		%AnimationPlayer.play("Activate3")
	if weak_point_2.die():
		%AnimationPlayer.play("Activate4")
	if weak_point_3.die():
		%AnimationPlayer.play("Activate2")

func die():
	Engine.time_scale = 0.5
	queue_free()
	get_tree().change_scene_to_file("res://Scenes/WinScreen.tscn")

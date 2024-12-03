extends CharacterBody2D

@onready var weak_point_1: Area2D = $WeakPoint1
@onready var weak_point_2: Area2D = $WeakPoint2
@onready var weak_point_3: Area2D = $WeakPoint3
@onready var weak_point_4: Area2D = $WeakPoint4
@onready var health_bar: ProgressBar = $CanvasLayer/HealthBar

var health = 4000
const GRAVITY = 20000
var direction: Vector2 = Vector2(0,0)

func _ready() -> void:
	if direction <= Vector2(0,1):
		%Robo.play_walk()
	if direction >= Vector2(1,0):
		%Robo.play_walk()
	%AnimationPlayer.play("protect")

func _process(delta: float) -> void:
	move_and_slide()
	move_local_x(6,0)
	move_local_x(-6,0)

func boss_take_damage():
	health -= 100
	%AnimationPlayer.play("hurt")
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


func _on_weak_point_1_boss_take_damage() -> void:
	boss_take_damage()

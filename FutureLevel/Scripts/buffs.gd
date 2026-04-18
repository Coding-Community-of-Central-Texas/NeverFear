extends Node

@onready var cash_up: CPUParticles2D = $CashUp
@onready var speed_up: CPUParticles2D = $SpeedUp
@onready var lives_up: CPUParticles2D = $LivesUp
@onready var health_up: CPUParticles2D = $HealthUp


func emit_cash_up():
	$CashUp.emitting = true

func emit_speed_up():
	$SpeedUp.emitting = true

func emit_lives_up():
	$LivesUp.emitting = true

func emit_health_up():
	$HealthUp.emitting = true

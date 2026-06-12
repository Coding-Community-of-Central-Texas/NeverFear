extends Node2D

signal request_pool_return(instance: Node)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D

var active := true
var pooled := false

func set_pooled(value: bool) -> void:
	pooled = value

func _ready():
	if not pooled:
		_play()


func _on_animated_sprite_2d_animation_finished() -> void:
	deactivate()

func activate(spawn_position: Vector2, _data: Dictionary = {}) -> void:
	active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	global_position = spawn_position
	_play()

func deactivate(return_to_pool: bool = true) -> void:
	if not active and return_to_pool:
		return

	active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	if animated_sprite:
		animated_sprite.stop()
	if audio_stream_player_2d:
		audio_stream_player_2d.stop()
	if cpu_particles_2d:
		cpu_particles_2d.emitting = false

	if pooled:
		if return_to_pool:
			request_pool_return.emit(self)
	elif return_to_pool:
		queue_free()

func _play() -> void:
	if animated_sprite:
		animated_sprite.visible = true
		animated_sprite.frame = 0
		animated_sprite.play("RobbieBoom")
	if audio_stream_player_2d:
		audio_stream_player_2d.play()
	if cpu_particles_2d:
		cpu_particles_2d.emitting = true
		cpu_particles_2d.restart()

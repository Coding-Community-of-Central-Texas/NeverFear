extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimatedSprite2D/AnimationPlayer



func _ready():
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)


func play_move(force: bool = false):
	if not force and _is_attack_playing():
		return
	_play_animation("move")

func play_hurt():
	_play_animation("hurt")

func play_attack():
	if animation_player != null:
		animation_player.stop()
	animated_sprite_2d.play("attack")

func _flip():
	animated_sprite_2d.flip_h = true

func _is_attack_playing() -> bool:
	return animated_sprite_2d.animation == "attack" and animated_sprite_2d.is_playing()

func _play_animation(animation_name: StringName) -> void:
	if animation_player != null and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		return

	if animated_sprite_2d.sprite_frames != null and animated_sprite_2d.sprite_frames.has_animation(animation_name):
		animated_sprite_2d.play(animation_name)

func _on_animation_finished():
	if animated_sprite_2d.animation == "attack":
		play_move(true)

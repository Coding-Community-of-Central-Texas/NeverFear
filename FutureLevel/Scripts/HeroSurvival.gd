extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var health = 100



func _physics_process(delta):
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * 600
	move_and_slide()
	handle_animation()

func handle_animation() -> void:
	if health <= 0:
		if not %AnimationPlayer.is_playing() or %AnimationPlayer.animation != "death":
			%AnimationPlayer.play("death")
		return

	if velocity.length() > 0:
		if velocity.x != 0:
			animated_sprite_2d.flip_h = velocity.x < 0  # Flip sprite when moving left
			%AnimationPlayer.play("walk")
		else:
			%AnimationPlayer.play("idle")

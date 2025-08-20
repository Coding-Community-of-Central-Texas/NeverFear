# grenade_explosion.gd
extends RigidBody2D

@onready var explosion: CollisionShape2D = $Area2D/Explosion
@onready var grenade_sprite: AnimatedSprite2D = $Area2D/AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $Area2D/Explosion/AnimationPlayer
@onready var explosion_sprite: AnimatedSprite2D = $Area2D/explosion
@onready var velocity := Vector2.ZERO

const GRAVITY = 100
var fuse_time := 0.8 # seconds before explosion
var exploded := false

func _ready():
	explosion_sprite.global_rotation_degrees = 0.0
	explosion.disabled = true
	grenade_sprite.play("thrown")
	await get_tree().create_timer(fuse_time - 0.2).timeout
	_pre_explode()
	await get_tree().create_timer(0.2).timeout
	_explode()

func _physics_process(delta):
	if not exploded:
		position += velocity * delta

func throw(direction: Vector2, force: float):
	velocity = direction.normalized() * force

func _pre_explode():
	grenade_sprite.play("boom")
	velocity = Vector2.ZERO
	set_physics_process(false)

func _explode():
	set_physics_process(false)
	self.velocity = Vector2(0,0)
	self.rotation = 0.0
	explosion_sprite.play("default")
	explosion.disabled = false
	anim_player.play("dmg")
	await anim_player.animation_finished
	queue_free()

func _on_body_entered(body):
	if explosion_sprite.animation == "explosion":
		if body.is_in_group("enemy"):
			body.apply_damage(100)
		if body.has_method("take_damage"):
			var dir = (body.global_position - global_position).normalized()
			body.apply_knockback(dir * 1000)

# res://actors/Grenade.gd
extends RigidBody2D

# --- Tunables ---
@export var fuse_time: float = 0.8
@export var telegraph_time: float = 0.3
@export var damage: int = 100
@export var knockback: float = 1000.0
@export var rigid_knockback: float = 1600.0
@export var affect_only_group: StringName = ""  # set to "enemy" if you only want that group
@export var throw_spin: float = 6.0
@export var gravity_scale_override: float = 1.0

# --- Scene refs ---
@onready var area_2d: Area2D = $Area2D                         # only used for layer/mask convenience
@onready var explosion_shape: CollisionShape2D = $Area2D/Explosion # CircleShape2D with your static radius
@onready var grenade_sprite: AnimatedSprite2D = $Area2D/AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $Area2D/Explosion/AnimationPlayer
@onready var explosion_anim: AnimatedSprite2D = $Area2D/explosion
@onready var audio: AudioStreamPlayer2D = $Area2D/AudioStreamPlayer2D

var exploded := false

func _ready() -> void:
	# Physics-driven arc.
	gravity_scale = gravity_scale_override

	# Explosion area is disabled until detonation.
	explosion_shape.disabled = true
	area_2d.monitoring = false

	grenade_sprite.play("thrown")
	await get_tree().create_timer(max(fuse_time - telegraph_time, 0.0)).timeout
	_pre_explode()
	await get_tree().create_timer(telegraph_time).timeout
	_explode()

func throw(direction: Vector2, force: float) -> void:
	linear_velocity = direction.normalized() * force
	angular_velocity = sign(direction.x) * throw_spin

func _pre_explode() -> void:
	# Brief slowdown so the grenade doesn't roll away while telegraphing.
	linear_velocity *= 0.2
	angular_velocity = 0.0

func _explode() -> void:
	if exploded:
		return
	exploded = true
	grenade_sprite.visible = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	explosion_anim.global_rotation = 0.0


	explosion_shape.set_deferred("disabled", false)
	_apply_blast()

	# VFX (non-blocking; keep it simple)
	if anim_player.has_animation("dmg"):
		anim_player.play("dmg")
		audio.play()
	explosion_anim.play("default")
	await anim_player.animation_finished

	# Cleanup
	explosion_shape.disabled = true
	area_2d.monitoring = false
	queue_free()

func _apply_blast() -> void:
	
	var shape := explosion_shape.shape
	if shape == null:
		return
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = explosion_shape.global_transform
	
	params.collision_mask = 0x7FFFFFFF
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.exclude = [get_rid()]

	var space := get_world_2d().direct_space_state
	var hits := space.intersect_shape(params, 64)
	for hit in hits:
		var collider = hit.get("collider")  # Variant on purpose (avoids inference errors)
		if collider == null:
			continue
		# Optional group filter
		if affect_only_group != StringName(""):
			var n := collider as Node
			if n == null or not n.is_in_group(affect_only_group):
				continue

		var node2d := collider as Node2D
		if node2d == null:
			continue
		var dir: Vector2 = (node2d.global_position - global_position).normalized()

		# Damage (method is optional on the target)
		if collider.has_method("take_damage"):
			collider.take_damage(50)

		# Knockback
		if collider.has_method("apply_knockback"):
			collider.apply_knockback(dir * knockback)
		elif collider is RigidBody2D:
			(collider as RigidBody2D).apply_impulse(dir * rigid_knockback)

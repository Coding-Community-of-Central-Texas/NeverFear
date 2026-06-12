# res://actors/Grenade.gd
extends RigidBody2D

signal request_pool_return(instance: Node)

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
@onready var body_shape: CollisionShape2D = $CollisionShape2D

var exploded := false
var active := true
var pooled := false
var _lifecycle_id := 0

func _ready() -> void:
	_reset_visual_state()
	if not pooled:
		activate(global_position, {})

func set_pooled(value: bool) -> void:
	pooled = value

func activate(spawn_position: Vector2, data: Dictionary = {}) -> void:
	_lifecycle_id += 1
	active = true
	exploded = false
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	global_position = spawn_position
	rotation = float(data.get("rotation", 0.0))
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = false
	freeze = false
	gravity_scale = float(data.get("gravity_scale_override", gravity_scale_override))
	lock_rotation = true

	if body_shape:
		body_shape.disabled = false
	if area_2d:
		area_2d.monitoring = false
		area_2d.monitorable = true
	if explosion_shape:
		explosion_shape.disabled = true

	_reset_visual_state()

	var throw_direction: Vector2 = data.get("throw_direction", Vector2.ZERO)
	var throw_force := float(data.get("throw_force", 0.0))
	if throw_direction != Vector2.ZERO and throw_force > 0.0:
		throw(throw_direction, throw_force)

	_begin_fuse_sequence()

func deactivate(return_to_pool: bool = true) -> void:
	if not active and return_to_pool:
		return

	_lifecycle_id += 1
	active = false
	exploded = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = true
	freeze = true
	gravity_scale = gravity_scale_override

	if body_shape:
		body_shape.disabled = true
	if explosion_shape:
		explosion_shape.disabled = true
	if area_2d:
		area_2d.monitoring = false
		area_2d.monitorable = false
	if anim_player:
		anim_player.stop()
	if explosion_anim:
		explosion_anim.visible = false
		explosion_anim.stop()
	if grenade_sprite:
		grenade_sprite.visible = false
		grenade_sprite.stop()
	if audio:
		audio.stop()

	if pooled:
		if return_to_pool:
			request_pool_return.emit(self)
	elif return_to_pool:
		queue_free()

func throw(direction: Vector2, force: float) -> void:
	linear_velocity = direction.normalized() * force
	angular_velocity = sign(direction.x) * throw_spin

func _begin_fuse_sequence() -> void:
	var lifecycle_id := _lifecycle_id
	await get_tree().create_timer(max(fuse_time - telegraph_time, 0.0)).timeout
	if lifecycle_id != _lifecycle_id or not active:
		return

	_pre_explode()
	await get_tree().create_timer(telegraph_time).timeout
	if lifecycle_id != _lifecycle_id or not active:
		return

	_explode(lifecycle_id)

func _pre_explode() -> void:
	if not active:
		return

	# Brief slowdown so the grenade doesn't roll away while telegraphing.
	linear_velocity *= 0.2
	angular_velocity = 0.0

func _explode(lifecycle_id: int) -> void:
	if not active or exploded:
		return
	exploded = true
	grenade_sprite.visible = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	explosion_anim.global_rotation = 0.0
	if body_shape:
		body_shape.disabled = true

	explosion_shape.disabled = false
	_apply_blast()

	# VFX (non-blocking; keep it simple)
	var waiting_for_animation := false
	if anim_player.has_animation("dmg"):
		anim_player.play("dmg")
		waiting_for_animation = true
	audio.play()
	explosion_anim.play("default")
	explosion_anim.visible = true
	if waiting_for_animation:
		await anim_player.animation_finished
	else:
		await explosion_anim.animation_finished

	# Cleanup
	if lifecycle_id != _lifecycle_id:
		return
	explosion_shape.disabled = true
	area_2d.monitoring = false
	deactivate()

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

func _reset_visual_state() -> void:
	if grenade_sprite:
		grenade_sprite.visible = true
		grenade_sprite.play("thrown")
	if explosion_anim:
		explosion_anim.visible = false
		explosion_anim.stop()
	if audio:
		audio.stop()

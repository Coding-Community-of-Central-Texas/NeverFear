extends Node
class_name SurvivalPoolManager

const ObjectPoolScript := preload("res://Scripts/ObjectPool.gd")

@export_category("Scenes")
@export var enemy_scenes: Array[PackedScene] = [
	preload("res://Scenes/DriodGauntlet.tscn"),
	preload("res://Scenes/OneHitGuantlet.tscn"),
	preload("res://Scenes/GauntletThreeHitter.tscn"),
	preload("res://Scenes/TankGauntlet.tscn"),
]
@export var player_bullet_scene: PackedScene = preload("res://Scenes/Bullet.tscn")
@export var shotgun_pellet_scene: PackedScene = preload("res://Scenes/ShotgunPellet.tscn")
@export var enemy_bullet_scene: PackedScene = preload("res://Scenes/EnemyBullet.tscn")
@export var tank_bullet_scene: PackedScene = preload("res://Scenes/TankBullet.tscn")
@export var boss_bullet_scene: PackedScene = preload("res://Scenes/BossBullet.tscn")
@export var grenade_scene: PackedScene = preload("res://Scenes/granade.tscn")
@export var cash_scene: PackedScene = preload("res://Scenes/Cash.tscn")
@export var effect_scenes: Array[PackedScene] = [
	preload("res://Scenes/Boom.tscn"),
	preload("res://Scenes/RobbieBoom.tscn"),
]

@export_category("Prewarm")
@export var enemy_pool_prewarm: int = 40
@export var player_bullet_pool_prewarm: int = 80
@export var enemy_bullet_pool_prewarm: int = 80
@export var boss_bullet_pool_prewarm: int = 24
@export var grenade_pool_prewarm: int = 8
@export var collectable_pool_prewarm: int = 40
@export var effect_pool_prewarm: int = 20

@export_category("Max Size")
@export var enemy_pool_max: int = 80
@export var player_bullet_pool_max: int = 120
@export var enemy_bullet_pool_max: int = 120
@export var boss_bullet_pool_max: int = 48
@export var grenade_pool_max: int = 14
@export var collectable_pool_max: int = 80
@export var effect_pool_max: int = 60

@export_category("Mobile Max Size")
@export var use_mobile_pool_limits: bool = true
@export var mobile_enemy_pool_max: int = 45
@export var mobile_player_bullet_pool_max: int = 80
@export var mobile_enemy_bullet_pool_max: int = 80
@export var mobile_boss_bullet_pool_max: int = 32
@export var mobile_grenade_pool_max: int = 10
@export var mobile_collectable_pool_max: int = 45
@export var mobile_effect_pool_max: int = 30

var _pools: Dictionary = {}

func _ready() -> void:
	add_to_group("survival_pool_manager")
	_apply_platform_limits()
	_prewarm_known_pools()

func spawn_enemy(enemy_scene: PackedScene, spawn_position: Vector2, data: Dictionary = {}) -> Node2D:
	return _spawn_from_pool(enemy_scene, "enemy", spawn_position, data) as Node2D

func spawn_player_bullet(spawn_position: Vector2, spawn_rotation: float, data: Dictionary = {}) -> Node2D:
	data["rotation"] = spawn_rotation
	return _spawn_from_pool(player_bullet_scene, "player_bullet", spawn_position, data) as Node2D

func spawn_shotgun_pellet(spawn_position: Vector2, spawn_rotation: float, data: Dictionary = {}) -> Node2D:
	data["rotation"] = spawn_rotation
	return _spawn_from_pool(shotgun_pellet_scene, "player_bullet", spawn_position, data) as Node2D

func spawn_enemy_bullet(spawn_position: Vector2, direction: Vector2, spawn_rotation: float = 0.0, bullet_scene: PackedScene = null) -> Node2D:
	var data := {
		"direction": direction,
		"rotation": spawn_rotation,
	}
	var scene_to_use := enemy_bullet_scene if bullet_scene == null else bullet_scene
	return _spawn_from_pool(scene_to_use, "enemy_bullet", spawn_position, data) as Node2D

func spawn_tank_bullet(spawn_position: Vector2, direction: Vector2, spawn_rotation: float = 0.0) -> Node2D:
	var data := {
		"direction": direction,
		"rotation": spawn_rotation,
	}
	return _spawn_from_pool(tank_bullet_scene, "enemy_bullet", spawn_position, data) as Node2D

func spawn_boss_bullet(spawn_position: Vector2, velocity: Vector2, data: Dictionary = {}) -> Node2D:
	data["velocity"] = velocity
	return _spawn_from_pool(boss_bullet_scene, "boss_bullet", spawn_position, data) as Node2D

func spawn_grenade(spawn_position: Vector2, direction: Vector2, throw_force: float, data: Dictionary = {}) -> RigidBody2D:
	data["throw_direction"] = direction
	data["throw_force"] = throw_force
	return _spawn_from_pool(grenade_scene, "grenade", spawn_position, data) as RigidBody2D

func spawn_cash(spawn_position: Vector2, randomize_power_up := true) -> Node2D:
	return _spawn_from_pool(cash_scene, "collectable", spawn_position, {"randomize_power_up": randomize_power_up}) as Node2D

func spawn_effect(effect_scene: PackedScene, spawn_position: Vector2, data: Dictionary = {}) -> Node2D:
	return _spawn_from_pool(effect_scene, "effect", spawn_position, data) as Node2D

func deactivate_or_free(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return

	if node.has_method("deactivate"):
		node.call("deactivate")
	else:
		node.queue_free()

func _prewarm_known_pools() -> void:
	var enemy_prewarm := _get_split_prewarm(enemy_pool_prewarm, enemy_scenes.size())
	for enemy_scene in enemy_scenes:
		_get_or_create_pool(enemy_scene, "enemy", enemy_prewarm, enemy_pool_max)

	var player_bullet_prewarm := _get_split_prewarm(player_bullet_pool_prewarm, 2)
	_get_or_create_pool(player_bullet_scene, "player_bullet", player_bullet_prewarm, player_bullet_pool_max)
	_get_or_create_pool(shotgun_pellet_scene, "player_bullet", player_bullet_prewarm, player_bullet_pool_max)

	var enemy_projectile_prewarm := _get_split_prewarm(enemy_bullet_pool_prewarm, 2)
	_get_or_create_pool(enemy_bullet_scene, "enemy_bullet", enemy_projectile_prewarm, enemy_bullet_pool_max)
	_get_or_create_pool(tank_bullet_scene, "enemy_bullet", enemy_projectile_prewarm, enemy_bullet_pool_max)
	_get_or_create_pool(boss_bullet_scene, "boss_bullet", boss_bullet_pool_prewarm, boss_bullet_pool_max)
	_get_or_create_pool(grenade_scene, "grenade", grenade_pool_prewarm, grenade_pool_max)
	_get_or_create_pool(cash_scene, "collectable", collectable_pool_prewarm, collectable_pool_max)

	var effect_prewarm := _get_split_prewarm(effect_pool_prewarm, effect_scenes.size())
	for effect_scene in effect_scenes:
		_get_or_create_pool(effect_scene, "effect", effect_prewarm, effect_pool_max)

func _spawn_from_pool(scene: PackedScene, category: String, spawn_position: Vector2, data: Dictionary) -> Node:
	var pool: Node = _get_or_create_pool(scene, category, 0, _get_category_max(category))
	if pool == null:
		return null

	return pool.call("get_instance", spawn_position, data) as Node

func _get_or_create_pool(scene: PackedScene, category: String, prewarm_count: int, max_count: int) -> Node:
	if scene == null:
		return null

	var key := _get_scene_key(scene, category)
	if _pools.has(key):
		return _pools[key] as Node

	var pool: Node = ObjectPoolScript.new()
	pool.name = _get_pool_name(scene, category)
	add_child(pool)
	pool.connect("pool_exhausted", Callable(self, "_on_pool_exhausted"))
	pool.call("setup", scene, prewarm_count, max_count)
	_pools[key] = pool
	return pool

func _get_category_max(category: String) -> int:
	match category:
		"enemy":
			return enemy_pool_max
		"player_bullet":
			return player_bullet_pool_max
		"enemy_bullet":
			return enemy_bullet_pool_max
		"boss_bullet":
			return boss_bullet_pool_max
		"grenade":
			return grenade_pool_max
		"collectable":
			return collectable_pool_max
		"effect":
			return effect_pool_max
		_:
			return 0

func _get_split_prewarm(total_count: int, scene_count: int) -> int:
	if total_count <= 0 or scene_count <= 0:
		return 0
	return maxi(1, int(ceil(float(total_count) / float(scene_count))))

func _apply_platform_limits() -> void:
	if not use_mobile_pool_limits:
		return

	var platform := OS.get_name()
	if platform != "iOS" and platform != "Android":
		return

	enemy_pool_max = mobile_enemy_pool_max
	player_bullet_pool_max = mobile_player_bullet_pool_max
	enemy_bullet_pool_max = mobile_enemy_bullet_pool_max
	boss_bullet_pool_max = mobile_boss_bullet_pool_max
	grenade_pool_max = mobile_grenade_pool_max
	collectable_pool_max = mobile_collectable_pool_max
	effect_pool_max = mobile_effect_pool_max

func _get_scene_key(scene: PackedScene, category: String) -> String:
	var scene_path := scene.resource_path
	if scene_path.is_empty():
		scene_path = str(scene.get_instance_id())
	return "%s:%s" % [category, scene_path]

func _get_pool_name(scene: PackedScene, category: String) -> String:
	var scene_name := scene.resource_path.get_file().get_basename()
	if scene_name.is_empty():
		scene_name = "RuntimeScene"
	return "%s_%sPool" % [category.capitalize(), scene_name]

func _on_pool_exhausted(scene_path: String) -> void:
	if scene_path.is_empty():
		push_warning("Survival pool exhausted for an unnamed scene; spawn skipped.")
	else:
		push_warning("Survival pool exhausted for %s; spawn skipped." % scene_path)

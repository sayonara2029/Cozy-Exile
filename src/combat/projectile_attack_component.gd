class_name ProjectileAttackComponent
extends Node3D
## Fires a projectile scene with a cooldown. Place it where shots should
## start (its height is the muzzle height); the actor decides direction.
##
## Stats live here for now. A future Skill resource would supply the
## projectile scene and numbers, and Skill Modifiers / Evolutions would change
## them before try_attack() runs, without touching Projectile or Health.

## Emitted after a projectile is spawned (presentation: cast pose, sounds).
signal attacked(direction: Vector3)

@export var projectile_scene: PackedScene
@export var cooldown: float = 0.28
@export var damage: float = 10.0
@export var damage_type: DamageInfo.Type = DamageInfo.Type.MAGIC
## Layers the projectile may hit/collide with (world + the enemy faction's hurtboxes).
@export_flags_3d_physics var projectile_mask: int = 1
## How far in front of the actor the projectile appears.
@export var spawn_forward_offset: float = 0.6
## The actor credited as damage source. Defaults to the parent node.
@export var source: Node

var _cooldown_left: float = 0.0


func _ready() -> void:
	if source == null:
		source = get_parent()


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func is_ready() -> bool:
	return _cooldown_left <= 0.0 and projectile_scene != null


## Fires along `direction` (flattened to the ground plane). Returns false while
## on cooldown or if the direction is unusable.
func try_attack(direction: Vector3) -> bool:
	if not is_ready():
		return false
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return false
	flat = flat.normalized()

	var projectile := projectile_scene.instantiate() as Projectile
	if projectile == null:
		push_error("projectile_scene must instance a Projectile")
		return false
	projectile.damage = damage
	projectile.damage_type = damage_type
	projectile.collision_mask = projectile_mask
	_spawn_parent().add_child(projectile)
	projectile.launch(global_position + flat * spawn_forward_offset, flat, source)

	_cooldown_left = cooldown
	attacked.emit(flat)
	return true


func _spawn_parent() -> Node:
	# Projectiles live in the scene root so they keep flying independently of the actor.
	var scene := get_tree().current_scene
	return scene if scene else get_tree().root

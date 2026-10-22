class_name SkillController
extends Node3D
## Casts one SkillData through the existing combat pipeline:
##   try_cast(dir) -> readiness / cooldown check -> spawn skill.projectile_scene
##   -> Projectile -> Hurtbox -> HealthComponent (unchanged from M03/M04).
##
## Holds no balance numbers of its own: damage, cooldown, speed, lifetime and
## colour all come from `skill`. Place it where shots start (muzzle height).
## Not input-specific: the player (player.gd) and AI (RangedEnemyBrain) both just
## call try_cast(). Faction = projectile_layer + projectile_mask set on this node.
## More skills = more SkillController nodes (or swap `skill` at runtime).

## A cast succeeded (presentation: cast pose, HUD).
signal cast(skill: SkillData, direction: Vector3)
## A cast was requested while unavailable (on cooldown / no skill). Nothing spawned.
signal cast_rejected(skill: SkillData)
## Cooldown finished; the skill can be cast again.
signal became_ready(skill: SkillData)

@export var skill: SkillData
## Faction of the projectiles (their own physics layer), e.g. player_projectiles
## (layer 4 = 8) or enemy_projectiles (layer 5 = 16). 0 = keep the scene's layer.
@export_flags_3d_physics var projectile_layer: int = 0
## Layers the projectiles may hit: world (1) + the *opposing* faction's hurtboxes
## (player casts: 1 + enemy_hurtboxes 128; enemy casts: 1 + player_hurtboxes 256).
@export_flags_3d_physics var projectile_mask: int = 1
## How far in front of the caster the projectile appears.
@export var spawn_forward_offset: float = 0.6
## Actor credited as damage source. Defaults to the parent node.
@export var source: Node

var _cooldown_left: float = 0.0


func _ready() -> void:
	if source == null:
		source = get_parent()


func _physics_process(delta: float) -> void:
	if _cooldown_left <= 0.0:
		return
	_cooldown_left -= delta
	if _cooldown_left <= 0.0:
		_cooldown_left = 0.0
		became_ready.emit(skill)


func has_skill() -> bool:
	return skill != null and skill.projectile_scene != null


func is_ready() -> bool:
	return has_skill() and _cooldown_left <= 0.0


func get_cooldown_left() -> float:
	return _cooldown_left


## 1 = just cast, 0 = ready.
func get_cooldown_ratio() -> float:
	if not has_skill() or skill.cooldown <= 0.0:
		return 0.0
	return clampf(_cooldown_left / skill.cooldown, 0.0, 1.0)


## Casts along `direction` (flattened to the ground). Returns false, emits
## cast_rejected and spawns nothing if the skill is unavailable.
func try_cast(direction: Vector3) -> bool:
	if not is_ready():
		cast_rejected.emit(skill)
		return false
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return false
	flat = flat.normalized()

	var projectile := skill.projectile_scene.instantiate() as Projectile
	if projectile == null:
		push_error("SkillData '%s': projectile_scene must instance a Projectile" % skill.id)
		return false
	projectile.damage = skill.base_damage
	projectile.damage_type = skill.damage_type
	projectile.speed = skill.projectile_speed
	projectile.lifetime = skill.projectile_lifetime
	if projectile_layer != 0:
		projectile.collision_layer = projectile_layer
	projectile.collision_mask = projectile_mask
	projectile.set_visual_material(skill.get_projectile_material())
	_spawn_parent().add_child(projectile)
	projectile.launch(global_position + flat * spawn_forward_offset, flat, source)

	_cooldown_left = skill.cooldown
	cast.emit(skill, flat)
	return true


func _spawn_parent() -> Node:
	# Projectiles live in the scene root so they keep flying independently of the caster.
	var scene := get_tree().current_scene
	return scene if scene else get_tree().root

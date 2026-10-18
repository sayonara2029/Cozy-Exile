class_name MeleeAttackComponent
extends Node3D
## Short-range attack with a readable timeline:
##   start_attack(dir) -> wind-up (telegraph) -> strike (damage) -> recovery -> cooldown
##
## The strike is a one-off sphere query in front of the attacker that only
## sees Hurtboxes on `hit_mask` (factions are physics layers, not code), so the
## same component works for enemies now and player/skill melee later.

signal windup_started(duration: float)
## hits = number of hurtboxes damaged by this strike.
signal struck(hits: int)
signal finished

enum Phase { READY, WINDUP, RECOVERY }

@export var damage: float = 8.0
@export var damage_type: DamageInfo.Type = DamageInfo.Type.PHYSICAL
@export var windup_time: float = 0.45
@export var recovery_time: float = 0.35
## Starts after recovery ends.
@export var cooldown: float = 1.2
## Strike sphere: centred this far in front of the component, with this radius.
@export var strike_forward: float = 0.8
@export var strike_radius: float = 0.9
## Layers whose hurtboxes this attack can hit (player_hurtboxes = layer 9 = 256).
@export_flags_3d_physics var hit_mask: int = 256
## Actor credited as the damage source; defaults to the parent.
@export var source: Node

var phase: Phase = Phase.READY

var _timer: float = 0.0
var _cooldown_left: float = 0.0
var _direction: Vector3 = Vector3.FORWARD
# Reused for every strike: no per-attack allocations.
var _query := PhysicsShapeQueryParameters3D.new()
var _shape := SphereShape3D.new()


func _ready() -> void:
	if source == null:
		source = get_parent()
	_query.shape = _shape
	_query.collide_with_areas = true
	_query.collide_with_bodies = false


func is_ready() -> bool:
	return phase == Phase.READY and _cooldown_left <= 0.0


func is_attacking() -> bool:
	return phase != Phase.READY


## Commits to an attack in `direction` (ground plane). Returns false if not ready.
func start_attack(direction: Vector3) -> bool:
	if not is_ready():
		return false
	var flat := Vector3(direction.x, 0.0, direction.z)
	_direction = flat.normalized() if flat.length_squared() > 0.0001 else Vector3.FORWARD
	phase = Phase.WINDUP
	_timer = windup_time
	windup_started.emit(windup_time)
	return true


## Aborts any attack in progress (e.g. the attacker died). No damage is dealt.
func cancel() -> void:
	phase = Phase.READY
	_timer = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if phase == Phase.READY:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	if phase == Phase.WINDUP:
		struck.emit(_strike())
		phase = Phase.RECOVERY
		_timer = recovery_time
	else:
		phase = Phase.READY
		_cooldown_left = cooldown
		finished.emit()


func _strike() -> int:
	_shape.radius = strike_radius
	_query.collision_mask = hit_mask
	_query.transform = Transform3D(Basis.IDENTITY, global_position + _direction * strike_forward)
	var results := get_world_3d().direct_space_state.intersect_shape(_query, 8)
	var hits := 0
	for result in results:
		var hurtbox := result["collider"] as Hurtbox
		if hurtbox == null or not hurtbox.can_be_hit():
			continue
		if is_instance_valid(source) and hurtbox.actor == source:
			continue
		var info := DamageInfo.new(damage, source, damage_type)
		info.direction = _direction
		info.hit_position = hurtbox.global_position
		hurtbox.receive_hit(info)
		hits += 1
	return hits

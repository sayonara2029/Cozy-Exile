class_name Player
extends CharacterBody3D
## Player actor. Thin glue only: routes input to the movement component and
## the skill controller, and keeps track of which way the character faces. Health,
## damage, hurtbox i-frames and projectiles live in reusable components.

## Emitted when health reaches zero. The composition root decides what follows.
signal downed

## How long the character keeps facing its last attack direction before
## turning back toward its movement direction.
const ATTACK_FACING_TIME := 0.3

## Knock-back speed added when hit.
@export var knockback_impulse: float = 5.0

## Gameplay facing (ground plane, normalized). Presentation reads this.
var facing: Vector3 = Vector3.FORWARD

var _attack_facing_left: float = 0.0

@onready var input_component: PlayerInputComponent = $PlayerInputComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var health: HealthComponent = $HealthComponent
@onready var skills: SkillController = $SkillController
@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	add_to_group(&"player")
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func is_alive() -> bool:
	return not health.is_dead()


func _physics_process(delta: float) -> void:
	if not is_alive():
		movement.move(self, Vector3.ZERO, delta)
		return
	var move_direction := input_component.get_move_direction()
	movement.move(self, move_direction, delta)

	_attack_facing_left = maxf(_attack_facing_left - delta, 0.0)
	# Holding = auto-cast whenever ready. A fresh press during cooldown is passed
	# through so the controller can report "not ready" (it spawns nothing).
	var held := input_component.is_attack_held()
	if held and (skills.is_ready() or input_component.is_attack_just_pressed()):
		var aim := input_component.get_aim_direction(skills.global_position, facing)
		if skills.try_cast(aim):
			facing = Vector3(aim.x, 0.0, aim.z).normalized()
			_attack_facing_left = ATTACK_FACING_TIME

	if _attack_facing_left <= 0.0 and move_direction.length_squared() > 0.01:
		facing = Vector3(move_direction.x, 0.0, move_direction.z).normalized()


## Full health, hittable again, at `world_position` (placeholder respawn).
func revive_at(world_position: Vector3) -> void:
	health.revive()
	hurtbox.enable()
	teleport_to(world_position)


func _on_damaged(info: DamageInfo, _applied: float) -> void:
	movement.apply_impulse(self, info.direction * knockback_impulse)


func _on_died(_info: DamageInfo) -> void:
	hurtbox.disable()
	downed.emit()


## Moves the player instantly (spawn, portals) without interpolation smear.
func teleport_to(world_position: Vector3) -> void:
	global_position = world_position
	velocity = Vector3.ZERO
	reset_physics_interpolation()

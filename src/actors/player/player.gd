class_name Player
extends CharacterBody3D
## Player actor. Thin glue only: routes input to the movement and attack
## components and keeps track of which way the character faces. Health,
## damage and projectiles live in their own reusable components.

## How long the character keeps facing its last attack direction before
## turning back toward its movement direction.
const ATTACK_FACING_TIME := 0.3

## Gameplay facing (ground plane, normalized). Presentation reads this.
var facing: Vector3 = Vector3.FORWARD

var _attack_facing_left: float = 0.0

@onready var input_component: PlayerInputComponent = $PlayerInputComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var health: HealthComponent = $HealthComponent
@onready var attack: ProjectileAttackComponent = $ProjectileAttack


func _ready() -> void:
	add_to_group(&"player")


func _physics_process(delta: float) -> void:
	var move_direction := input_component.get_move_direction()
	movement.move(self, move_direction, delta)

	_attack_facing_left = maxf(_attack_facing_left - delta, 0.0)
	if input_component.is_attack_held() and attack.is_ready():
		var aim := input_component.get_aim_direction(attack.global_position, facing)
		if attack.try_attack(aim):
			facing = Vector3(aim.x, 0.0, aim.z).normalized()
			_attack_facing_left = ATTACK_FACING_TIME

	if _attack_facing_left <= 0.0 and move_direction.length_squared() > 0.01:
		facing = Vector3(move_direction.x, 0.0, move_direction.z).normalized()


## Moves the player instantly (spawn, portals) without interpolation smear.
func teleport_to(world_position: Vector3) -> void:
	global_position = world_position
	velocity = Vector3.ZERO
	reset_physics_interpolation()

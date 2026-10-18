class_name MovementComponent
extends Node
## Ground movement for any CharacterBody3D (player now, enemies/NPCs later).
##
## It knows nothing about where the direction comes from: a player input
## component, an AI brain or a dash skill can all feed it through move().
## Stats/buffs can later scale speed through speed_multiplier without
## touching this script.

## Emitted when the body starts or stops moving (animation, footsteps, VFX later).
signal moving_changed(is_moving: bool)

@export var move_speed: float = 6.0
@export var acceleration: float = 45.0
@export var deceleration: float = 60.0
@export var gravity_scale: float = 1.0
## Horizontal speed below which the body counts as standing still.
@export var moving_threshold: float = 0.15

## Multiplier hook for future stats, buffs and slows. 1.0 = base speed.
var speed_multiplier: float = 1.0
var is_moving: bool = false

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


## Applies one physics step of movement. direction is world-space; Y is ignored.
func move(body: CharacterBody3D, direction: Vector3, delta: float) -> void:
	direction.y = 0.0
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	var horizontal := Vector3(body.velocity.x, 0.0, body.velocity.z)
	var target := direction * move_speed * speed_multiplier
	var rate := acceleration if direction != Vector3.ZERO else deceleration
	horizontal = horizontal.move_toward(target, rate * delta)

	var vertical := body.velocity.y
	if body.is_on_floor():
		vertical = 0.0
	else:
		vertical -= _gravity * gravity_scale * delta

	body.velocity = Vector3(horizontal.x, vertical, horizontal.z)
	body.move_and_slide()
	_update_moving_state(body)


## Instant horizontal push (knock-back). It fades out through the normal
## acceleration / deceleration of the next move() calls.
func apply_impulse(body: CharacterBody3D, impulse: Vector3) -> void:
	body.velocity += Vector3(impulse.x, 0.0, impulse.z)


func get_horizontal_speed(body: CharacterBody3D) -> float:
	return Vector2(body.velocity.x, body.velocity.z).length()


func _update_moving_state(body: CharacterBody3D) -> void:
	var now_moving := get_horizontal_speed(body) > moving_threshold
	if now_moving != is_moving:
		is_moving = now_moving
		moving_changed.emit(is_moving)

extends Node3D
## Presentation only: turns the placeholder model toward its movement and adds
## a small cozy walk bounce / idle breathing. Gameplay never reads from here,
## so this node can be replaced by an animated GLB model later.
##
## Runs in _physics_process so it rides physics interpolation smoothly.

@export var body: CharacterBody3D
@export var movement: MovementComponent
@export var turn_sharpness: float = 14.0
@export var bob_height: float = 0.09
@export var bob_frequency: float = 15.0
@export var squash_amount: float = 0.05
@export var breath_frequency: float = 2.2
@export var breath_amount: float = 0.015

var _walking: bool = false
var _walk_phase: float = 0.0
var _idle_time: float = 0.0


func _ready() -> void:
	if movement:
		movement.moving_changed.connect(_on_moving_changed)


func _physics_process(delta: float) -> void:
	if body == null:
		return
	_update_facing(delta)
	_update_bounce(delta)


func _update_facing(delta: float) -> void:
	var flat := Vector2(body.velocity.x, body.velocity.z)
	if flat.length_squared() < 0.04:
		return
	# Model faces -Z (Godot forward), so aim -Z along the velocity.
	var target_yaw := atan2(-body.velocity.x, -body.velocity.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_sharpness * delta))


func _update_bounce(delta: float) -> void:
	var weight := 1.0 - exp(-12.0 * delta)
	if _walking:
		_walk_phase += delta * bob_frequency
		var wave := absf(sin(_walk_phase))
		position.y = lerpf(position.y, wave * bob_height, weight)
		var squash := 1.0 + (wave - 0.5) * squash_amount
		scale = scale.lerp(Vector3(1.0 / sqrt(squash), squash, 1.0 / sqrt(squash)), weight)
	else:
		_idle_time += delta
		var breath := 1.0 + sin(_idle_time * breath_frequency) * breath_amount
		position.y = lerpf(position.y, 0.0, weight)
		scale = scale.lerp(Vector3(1.0, breath, 1.0), weight)


func _on_moving_changed(is_moving: bool) -> void:
	_walking = is_moving
	if not is_moving:
		_walk_phase = 0.0

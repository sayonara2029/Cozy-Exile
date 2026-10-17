extends Node3D
## Presentation glue for the player: turns the model toward the player's
## facing (movement or attack direction) and forwards locomotion / cast state
## to the model's animator. Gameplay never reads
## from here, so the model can be swapped (e.g. for a rigged GLB) freely.
##
## Runs in _physics_process so it rides physics interpolation smoothly.

@export var body: Player
@export var movement: MovementComponent
@export var attack: ProjectileAttackComponent
@export var model: PlayerModel
@export var turn_sharpness: float = 14.0
## Strength of the squash "pop" when starting / stopping.
@export var start_pulse: float = 0.8
@export var stop_pulse: float = 0.5


func _ready() -> void:
	if movement:
		movement.moving_changed.connect(_on_moving_changed)
	if attack:
		attack.attacked.connect(_on_attacked)


func _physics_process(delta: float) -> void:
	if body == null:
		return
	_update_facing(delta)
	if model and movement:
		var max_speed := maxf(movement.move_speed * movement.speed_multiplier, 0.01)
		model.set_locomotion(movement.get_horizontal_speed(body) / max_speed)


func _update_facing(delta: float) -> void:
	var facing := body.facing
	if Vector2(facing.x, facing.z).length_squared() < 0.0001:
		return
	# Model faces -Z (Godot forward), so aim -Z along the facing direction.
	var target_yaw := atan2(-facing.x, -facing.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_sharpness * delta))


func _on_attacked(_direction: Vector3) -> void:
	if model:
		model.play_cast()


func _on_moving_changed(is_moving: bool) -> void:
	if model:
		model.pulse(start_pulse if is_moving else stop_pulse)

class_name ARPGCamera
extends Node3D
## Perspective isometric-style ARPG camera rig.
##
## The rig sits on the target; pitch/yaw are applied to the rig and the
## Camera3D child is pushed back along local +Z by the zoom distance.
## Follow runs in _process using the target's interpolated transform, so it is
## smooth on high refresh-rate monitors while physics runs at a fixed tick.

signal zoom_changed(distance: float)

@export var target: Node3D
@export var yaw_degrees: float = 45.0
## Pitch when fully zoomed in (a little flatter: shows the character more).
@export_range(-85.0, -15.0, 0.5) var pitch_near_degrees: float = -44.0
## Pitch when fully zoomed out (steeper: shows more of the battlefield).
@export_range(-85.0, -15.0, 0.5) var pitch_far_degrees: float = -56.0
## Aim point above the target's origin (roughly chest height).
@export var look_offset: Vector3 = Vector3(0.0, 0.7, 0.0)
## Higher = tighter follow. Exponential smoothing never overshoots.
@export var follow_sharpness: float = 12.0

@export_group("Zoom")
@export var min_distance: float = 6.5
@export var max_distance: float = 20.0
@export var start_distance: float = 12.0
@export var zoom_step: float = 1.25
@export var zoom_sharpness: float = 11.0

var target_distance: float
var current_distance: float

var _shake_amount: float = 0.0
var _shake_time_left: float = 0.0
var _shake_duration: float = 0.0
var _shake_seed: float = 0.0

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	# The rig is moved manually in _process; never interpolate it.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	target_distance = clampf(start_distance, min_distance, max_distance)
	current_distance = target_distance
	_apply_distance()
	snap_to_target()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"camera_zoom_in"):
		set_zoom(target_distance - zoom_step)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"camera_zoom_out"):
		set_zoom(target_distance + zoom_step)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if is_instance_valid(target):
		var goal := _target_focus()
		global_position = global_position.lerp(goal, 1.0 - exp(-follow_sharpness * delta))

	current_distance = lerpf(current_distance, target_distance, 1.0 - exp(-zoom_sharpness * delta))
	_apply_distance()
	_update_shake(delta)


func set_zoom(distance: float) -> void:
	var clamped := clampf(distance, min_distance, max_distance)
	if is_equal_approx(clamped, target_distance):
		return
	target_distance = clamped
	zoom_changed.emit(target_distance)


## Small screen shake. Uses the camera's h/v offsets (a lens shift), so the rig's
## follow position never drifts. Overlapping calls keep the strongest shake.
func shake(amount: float, duration: float) -> void:
	if amount <= 0.0 or duration <= 0.0:
		return
	if amount >= _shake_amount * (_shake_time_left / maxf(_shake_duration, 0.001)):
		_shake_amount = amount
		_shake_duration = duration
		_shake_time_left = duration
		_shake_seed = randf() * 100.0


func is_shaking() -> bool:
	return _shake_time_left > 0.0


func _update_shake(delta: float) -> void:
	if _shake_time_left <= 0.0:
		return
	_shake_time_left -= delta
	if _shake_time_left <= 0.0:
		_shake_time_left = 0.0
		_shake_amount = 0.0
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		return
	var strength := _shake_amount * (_shake_time_left / _shake_duration)
	var t := _shake_seed + _shake_time_left * 60.0
	camera.h_offset = sin(t * 1.7) * strength
	camera.v_offset = cos(t * 2.3) * strength


## Jumps straight to the target (spawn, teleport) with no smoothing.
func snap_to_target() -> void:
	if is_instance_valid(target):
		global_position = _target_focus()


## Places the camera on the rig's local +Z and blends pitch with zoom.
func _apply_distance() -> void:
	var t := inverse_lerp(min_distance, max_distance, current_distance)
	var pitch := lerpf(pitch_near_degrees, pitch_far_degrees, clampf(t, 0.0, 1.0))
	rotation_degrees = Vector3(pitch, yaw_degrees, 0.0)
	camera.position = Vector3(0.0, 0.0, current_distance)


func _target_focus() -> Vector3:
	return target.get_global_transform_interpolated().origin + look_offset

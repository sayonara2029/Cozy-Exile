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
@export_range(-85.0, -15.0, 0.5) var pitch_degrees: float = -52.0
@export var yaw_degrees: float = 45.0
## Aim point above the target's origin (roughly chest height).
@export var look_offset: Vector3 = Vector3(0.0, 0.8, 0.0)
@export var follow_sharpness: float = 9.0

@export_group("Zoom")
@export var min_distance: float = 7.0
@export var max_distance: float = 26.0
@export var start_distance: float = 15.0
@export var zoom_step: float = 1.5
@export var zoom_sharpness: float = 10.0

var target_distance: float
var current_distance: float

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	# The rig is moved manually in _process; never interpolate it.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0.0)
	target_distance = clampf(start_distance, min_distance, max_distance)
	current_distance = target_distance
	camera.position = Vector3(0.0, 0.0, current_distance)
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
	camera.position.z = current_distance


func set_zoom(distance: float) -> void:
	var clamped := clampf(distance, min_distance, max_distance)
	if is_equal_approx(clamped, target_distance):
		return
	target_distance = clamped
	zoom_changed.emit(target_distance)


## Jumps straight to the target (spawn, teleport) with no smoothing.
func snap_to_target() -> void:
	if is_instance_valid(target):
		global_position = _target_focus()


func _target_focus() -> Vector3:
	return target.get_global_transform_interpolated().origin + look_offset

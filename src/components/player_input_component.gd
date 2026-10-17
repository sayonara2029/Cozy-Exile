class_name PlayerInputComponent
extends Node
## Reads player movement input and turns it into a world-space direction
## relative to the active camera, so "W" always means "up the screen".
##
## Only reads input; it never moves anything. Swap it for an AI component
## to drive the same MovementComponent.


func get_move_direction() -> Vector3:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if input == Vector2.ZERO:
		return Vector3.ZERO

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3(input.x, 0.0, input.y)

	var basis := camera.global_basis
	var forward := Vector3(-basis.z.x, 0.0, -basis.z.z)
	var right := Vector3(basis.x.x, 0.0, basis.x.z)
	if forward.length_squared() < 0.0001 or right.length_squared() < 0.0001:
		return Vector3(input.x, 0.0, input.y)

	return right.normalized() * input.x - forward.normalized() * input.y

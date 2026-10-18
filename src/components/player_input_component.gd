class_name PlayerInputComponent
extends Node
## Reads player movement input and turns it into a world-space direction
## relative to the active camera, so "W" always means "up the screen".
##
## Only reads input; it never moves or attacks. Swap it for an AI component
## to drive the same MovementComponent / SkillController.


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


## True while the attack button (left mouse or Space) is held: holding = auto-fire.
func is_attack_held() -> bool:
	return Input.is_action_pressed(&"attack_primary")


## True only on the tick the attack button goes down (used for "not ready" feedback).
func is_attack_just_pressed() -> bool:
	return Input.is_action_just_pressed(&"attack_primary")


## Aim direction on the ground plane. With the mouse button held it points at
## the cursor; otherwise (Space / keyboard play) it returns `fallback`, the
## direction the character is facing.
func get_aim_direction(from: Vector3, fallback: Vector3) -> Vector3:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return fallback
	var target: Variant = get_cursor_ground_point(from.y)
	if target == null:
		return fallback
	var flat := Vector3(target.x - from.x, 0.0, target.z - from.z)
	return flat.normalized() if flat.length_squared() > 0.01 else fallback


## Point under the mouse cursor on the horizontal plane y = height (null if none).
func get_cursor_ground_point(height: float) -> Variant:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	var mouse := get_viewport().get_mouse_position()
	var plane := Plane(Vector3.UP, height)
	return plane.intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))

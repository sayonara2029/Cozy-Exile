class_name EnemyVisual
extends Node3D
## Presentation for any enemy model: idle bob, hit flash, knock-back shake,
## squash, damage numbers and a short death animation.
##
## Gameplay never reads from here. Works with any MeshInstance3D children,
## so a future GLB model can reuse it unchanged.

@export_group("Hit")
## Overlay drawn on every mesh for a moment when hit (shared material, no per-enemy copies).
@export var flash_material: Material
@export var flash_time: float = 0.1
@export var knockback_distance: float = 0.22
@export var hit_squash: float = 0.22
@export var recover_sharpness: float = 14.0
@export var damage_number_scene: PackedScene
@export var damage_number_height: float = 1.3

@export_group("Idle")
@export var bob_height: float = 0.05
@export var bob_speed: float = 3.0
## Turn the model to look at the nearest node of this group (visual only, no AI).
@export var look_at_group: StringName = &"player"
@export var look_range: float = 12.0
@export var turn_sharpness: float = 5.0

@export_group("Death")
@export var death_time: float = 0.45

var _meshes: Array[GeometryInstance3D] = []
var _flash_left: float = 0.0
var _knock: Vector3 = Vector3.ZERO
var _squash: float = 0.0
var _time: float = 0.0
var _dying: bool = false


func _ready() -> void:
	# Animated in _process; the actor itself never moves in M03.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_time = randf() * TAU
	for node in find_children("*", "GeometryInstance3D", true, false):
		_meshes.append(node as GeometryInstance3D)


func play_hit(info: DamageInfo, applied: float) -> void:
	if _dying and applied <= 0.0:
		return
	_set_flash(true)
	_flash_left = flash_time
	var push := Vector3(info.direction.x, 0.0, info.direction.z)
	if push.length_squared() > 0.0001:
		_knock = push.normalized() * knockback_distance
	_squash = 1.0
	_spawn_damage_number(applied)


## Shrinks and spins the model, then returns (await it before freeing the actor).
func play_death() -> void:
	_dying = true
	_set_flash(true)
	_flash_left = flash_time
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3(1.25, 0.6, 1.25), death_time * 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector3.ZERO, death_time * 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation:y", rotation.y + TAU * 0.5, death_time * 0.7)
	await tween.finished


func _process(delta: float) -> void:
	_time += delta
	var weight := 1.0 - exp(-recover_sharpness * delta)
	_knock = _knock.lerp(Vector3.ZERO, weight)
	_squash = lerpf(_squash, 0.0, weight)
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0 and not _dying:
			_set_flash(false)
	if _dying:
		return
	_update_look(delta)
	var bob := (sin(_time * bob_speed) * 0.5 + 0.5) * bob_height
	position = _knock + Vector3(0.0, bob, 0.0)
	var s := _squash * hit_squash
	scale = Vector3(1.0 + s * 0.6, 1.0 - s, 1.0 + s * 0.6)


func _update_look(delta: float) -> void:
	if look_at_group == &"":
		return
	var target := get_tree().get_first_node_in_group(look_at_group) as Node3D
	if target == null:
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() > look_range * look_range or to_target.length_squared() < 0.01:
		return
	# Model faces -Z, so aim -Z at the target.
	var yaw := atan2(-to_target.x, -to_target.z)
	global_rotation.y = lerp_angle(global_rotation.y, yaw, 1.0 - exp(-turn_sharpness * delta))


func _set_flash(on: bool) -> void:
	for mesh in _meshes:
		mesh.material_overlay = flash_material if on else null


func _spawn_damage_number(amount: float) -> void:
	if damage_number_scene == null or amount <= 0.0:
		return
	var number := damage_number_scene.instantiate() as DamageNumber
	var scene := get_tree().current_scene
	(scene if scene else get_tree().root).add_child(number)
	number.show_amount(global_position + Vector3(randf_range(-0.2, 0.2), damage_number_height, 0.0), amount)

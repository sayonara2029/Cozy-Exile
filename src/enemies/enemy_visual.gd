class_name EnemyVisual
extends Node3D
## Runs on physics ticks (interpolated). Presentation for any enemy model: idle bob / movement hop, attack
## telegraph and lunge, hit flash, knock-back shake, squash, damage numbers
## and a short death animation.
##
## Gameplay never reads from here. Works with any MeshInstance3D children,
## so a future GLB model can reuse it unchanged.

@export_group("Hit")
## Overlay drawn on every mesh for a moment when hit (shared material, no per-enemy copies).
@export var flash_material: Material
## Meshes that receive the flash/telegraph overlay (each adds a draw call while
## shown). Empty = every mesh under this node. Pick the big silhouette parts.
@export var overlay_meshes: Array[NodePath] = []
@export var flash_time: float = 0.1
@export var knockback_distance: float = 0.22
@export var hit_squash: float = 0.22
@export var recover_sharpness: float = 14.0
@export var damage_number_scene: PackedScene
@export var damage_number_height: float = 1.3

@export_group("Attack")
## Overlay shown during the attack wind-up (danger colour). Hit flash wins over it.
@export var telegraph_material: Material
## How much the model swells upward while winding up.
@export var windup_stretch: float = 0.25
@export var lunge_distance: float = 0.35

@export_group("Idle / Move")
## Optional: the moving body, used to hop while walking.
@export var body: CharacterBody3D
@export var reference_speed: float = 2.6
@export var hop_height: float = 0.16
@export var hop_speed: float = 9.0
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
var _windup_left: float = 0.0
var _windup_time: float = 0.0
var _lunge: float = 0.0


func _ready() -> void:
	# Animated on physics ticks so it rides physics interpolation with the moving body.
	_time = randf() * TAU
	if overlay_meshes.is_empty():
		for node in find_children("*", "GeometryInstance3D", true, false):
			_meshes.append(node as GeometryInstance3D)
	else:
		for path in overlay_meshes:
			var mesh := get_node_or_null(path) as GeometryInstance3D
			if mesh:
				_meshes.append(mesh)


func play_hit(info: DamageInfo, applied: float) -> void:
	if _dying and applied <= 0.0:
		return
	_flash_left = flash_time
	_refresh_overlay()
	var push := Vector3(info.direction.x, 0.0, info.direction.z)
	if push.length_squared() > 0.0001:
		_knock = push.normalized() * knockback_distance
	_squash = 1.0
	_spawn_damage_number(applied)


## Shrinks and spins the model, then returns (await it before freeing the actor).
func play_death() -> void:
	_dying = true
	_windup_left = 0.0
	_flash_left = flash_time
	_refresh_overlay()
	var tween := create_tween().set_parallel(true).set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "scale", Vector3(1.25, 0.6, 1.25), death_time * 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector3.ZERO, death_time * 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation:y", rotation.y + TAU * 0.5, death_time * 0.7)
	await tween.finished


func _physics_process(delta: float) -> void:
	_time += delta
	var weight := 1.0 - exp(-recover_sharpness * delta)
	_knock = _knock.lerp(Vector3.ZERO, weight)
	_squash = lerpf(_squash, 0.0, weight)
	_lunge = lerpf(_lunge, 0.0, 1.0 - exp(-8.0 * delta))
	if _flash_left > 0.0 or _windup_left > 0.0:
		var flash_was := _flash_left > 0.0
		var windup_was := _windup_left > 0.0
		_flash_left = maxf(_flash_left - delta, 0.0)
		_windup_left = maxf(_windup_left - delta, 0.0)
		if not _dying and (flash_was != (_flash_left > 0.0) or windup_was != (_windup_left > 0.0)):
			_refresh_overlay()
	if _dying:
		return
	_update_look(delta)
	# Idle bob, replaced by a bouncy hop while moving.
	var move_ratio := 0.0
	if body:
		move_ratio = clampf(Vector2(body.velocity.x, body.velocity.z).length() / reference_speed, 0.0, 1.0)
	var bob := (sin(_time * bob_speed) * 0.5 + 0.5) * bob_height * (1.0 - move_ratio)
	var hop := absf(sin(_time * hop_speed)) * hop_height * move_ratio
	var forward := -global_basis.z
	position = _knock + forward * _lunge * lunge_distance + Vector3(0.0, bob + hop, 0.0)
	# Hit squash, plus a slow upward swell during the wind-up (telegraph).
	var s := _squash * hit_squash
	var w := 0.0
	if _windup_left > 0.0 and _windup_time > 0.0:
		w = (1.0 - _windup_left / _windup_time) * windup_stretch
	scale = Vector3(1.0 + s * 0.6 - w * 0.3, 1.0 - s + w, 1.0 + s * 0.6 - w * 0.3)


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


## Attack telegraph: warning tint + swell for `duration` seconds.
func play_windup(duration: float) -> void:
	if _dying:
		return
	_windup_time = duration
	_windup_left = duration
	_refresh_overlay()


## The moment the attack lands: quick lunge toward the facing direction.
func play_strike() -> void:
	_windup_left = 0.0
	_lunge = 1.0
	_squash = 0.6
	_refresh_overlay()


## One overlay at a time: hit flash > telegraph > none. Shared materials only.
func _refresh_overlay() -> void:
	var overlay: Material = null
	if _flash_left > 0.0:
		overlay = flash_material
	elif _windup_left > 0.0:
		overlay = telegraph_material
	for mesh in _meshes:
		mesh.material_overlay = overlay


func _spawn_damage_number(amount: float) -> void:
	if damage_number_scene == null or amount <= 0.0:
		return
	var number := damage_number_scene.instantiate() as DamageNumber
	var scene := get_tree().current_scene
	(scene if scene else get_tree().root).add_child(number)
	number.show_amount(global_position + Vector3(randf_range(-0.2, 0.2), damage_number_height, 0.0), amount)

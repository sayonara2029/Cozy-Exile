extends Node3D
## Presentation glue for the player: turns the model toward the player's
## facing (movement or attack direction) and forwards locomotion / cast state
## to the model's animator. Gameplay never reads
## from here, so the model can be swapped (e.g. for a rigged GLB) freely.
##
## Runs in _physics_process so it rides physics interpolation smoothly.

@export var body: Player
@export var movement: MovementComponent
@export var skills: SkillController
@export var health: HealthComponent
@export var hurtbox: Hurtbox
@export var model: PlayerModel
## Shared overlay shown briefly when the player is hit.
@export var hit_flash_material: Material
## Meshes (relative to this node) that flash when hit; each adds a draw call while
## shown. Empty = every mesh of the model.
@export var flash_meshes: Array[NodePath] = []
@export var hit_flash_time: float = 0.12
## Blink rate (Hz) while the hurtbox is invulnerable after a hit.
@export var blink_rate: float = 14.0
@export var turn_sharpness: float = 14.0
## Strength of the squash "pop" when starting / stopping.
@export var start_pulse: float = 0.8
@export var stop_pulse: float = 0.5


func _ready() -> void:
	if movement:
		movement.moving_changed.connect(_on_moving_changed)
	if skills:
		skills.cast.connect(_on_cast)
	if health:
		health.damaged.connect(_on_damaged)
		health.died.connect(_on_died)
		health.health_changed.connect(_on_health_changed)
	if model and flash_meshes.is_empty():
		for node in model.find_children("*", "GeometryInstance3D", true, false):
			_meshes.append(node as GeometryInstance3D)
	for path in flash_meshes:
		var mesh := get_node_or_null(path) as GeometryInstance3D
		if mesh:
			_meshes.append(mesh)


var _meshes: Array[GeometryInstance3D] = []
var _flash_left: float = 0.0
var _blink_time: float = 0.0
var _downed: bool = false


func _physics_process(delta: float) -> void:
	if body == null:
		return
	_update_hit_feedback(delta)
	if _downed:
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


func _update_hit_feedback(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_set_overlay(null)
	# Blink while invulnerable so the i-frames are readable.
	if model and hurtbox and hurtbox.is_invulnerable() and not _downed:
		_blink_time += delta
		model.visible = fmod(_blink_time * blink_rate, 1.0) < 0.6
	elif model and not model.visible:
		model.visible = true
		_blink_time = 0.0


func _set_overlay(material: Material) -> void:
	for mesh in _meshes:
		mesh.material_overlay = material


func _on_damaged(_info: DamageInfo, applied: float) -> void:
	if applied <= 0.0:
		return
	_flash_left = hit_flash_time
	_set_overlay(hit_flash_material)
	if model:
		model.pulse(1.0)


func _on_died(_info: DamageInfo) -> void:
	_downed = true
	if model:
		model.visible = true
		var tween := model.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tween.tween_property(model, "rotation:x", deg_to_rad(80.0), 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


func _on_health_changed(current: float, maximum: float) -> void:
	# Revived: stand back up.
	if _downed and current >= maximum and model:
		_downed = false
		model.rotation.x = 0.0


func _on_cast(_skill: SkillData, _direction: Vector3) -> void:
	if model:
		model.play_cast()


func _on_moving_changed(is_moving: bool) -> void:
	if model:
		model.pulse(start_pulse if is_moving else stop_pulse)

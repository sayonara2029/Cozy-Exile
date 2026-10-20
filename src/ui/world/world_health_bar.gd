class_name WorldHealthBar
extends Node3D
## Small health bar floating above an actor: two quads with shared materials
## (2 draw calls while shown). Driven only by HealthComponent signals.
## Hidden at full health and on death; faces the camera only while visible.

@export var health: HealthComponent
## Width of the fill at 100 % (must match the Fill quad's size.x).
@export var fill_width: float = 0.86

@onready var _fill: MeshInstance3D = $Fill


func _ready() -> void:
	visible = false
	set_physics_process(false)
	if health:
		health.health_changed.connect(_on_health_changed)
		health.died.connect(_on_died)


func get_ratio() -> float:
	return clampf(health.current_health / health.max_health, 0.0, 1.0) if health and health.max_health > 0.0 else 0.0


func _on_health_changed(current: float, maximum: float) -> void:
	var ratio := clampf(current / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	# Shrink from the right: keep the left edge fixed.
	_fill.scale.x = maxf(ratio, 0.001)
	_fill.position.x = -fill_width * (1.0 - ratio) * 0.5
	visible = current > 0.0 and current < maximum
	set_physics_process(visible)
	if visible:
		_face_camera()


func _on_died(_info: DamageInfo) -> void:
	visible = false
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	_face_camera()


func _face_camera() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		global_basis = camera.global_basis

class_name Projectile
extends Area3D
## Reusable straight-flying projectile. Knows nothing about who fired it beyond
## a `source` reference: the caster (SkillController) sets damage, type, speed,
## lifetime, collision mask and look from a SkillData, then calls launch().
## The exported values below are only fallbacks for projectiles used directly.
##
## Hits: any Hurtbox on a masked layer (area_entered) -> deals damage.
## Blocks: any physics body on a masked layer, e.g. world (body_entered).
## Ends on the first hit, on hitting the world, or when lifetime runs out.

signal hit(target: Hurtbox, info: DamageInfo)
signal finished

@export var speed: float = 16.0
@export var lifetime: float = 1.2
@export var damage: float = 10.0
@export var damage_type: DamageInfo.Type = DamageInfo.Type.MAGIC
## Spawned at the end point (hit, wall or expiry). Optional.
@export var impact_scene: PackedScene

var direction: Vector3 = Vector3.FORWARD
var source: Node = null

var _age: float = 0.0
var _spent: bool = false
var _visual_material: Material = null


func _ready() -> void:
	add_to_group(&"projectiles")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


## Tints every mesh of this projectile (and its impact) with a shared material.
## Call before adding to the tree or any time after.
func set_visual_material(material: Material) -> void:
	_visual_material = material
	for node in find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).material_override = material


## Places the projectile and sends it flying. Call after adding it to the tree.
func launch(origin: Vector3, travel_direction: Vector3, attacker: Node) -> void:
	direction = Vector3(travel_direction.x, 0.0, travel_direction.z).normalized()
	if direction == Vector3.ZERO:
		direction = Vector3.FORWARD
	source = attacker
	global_transform = Transform3D(Basis.looking_at(direction), origin)
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if _spent:
		return
	global_position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		_finish()


func _on_area_entered(area: Area3D) -> void:
	if _spent:
		return
	var hurtbox := area as Hurtbox
	if hurtbox == null or not hurtbox.can_be_hit():
		return
	if is_instance_valid(source) and hurtbox.actor == source:
		return
	var info := DamageInfo.new(damage, source if is_instance_valid(source) else null, damage_type)
	info.hit_position = global_position
	info.direction = direction
	hurtbox.receive_hit(info)
	hit.emit(hurtbox, info)
	_finish()


func _on_body_entered(body: Node3D) -> void:
	if _spent or body == source:
		return
	_finish()


func _finish() -> void:
	if _spent:
		return
	_spent = true
	set_deferred(&"monitoring", false)
	if impact_scene:
		var impact := impact_scene.instantiate() as Node3D
		if _visual_material and impact is GeometryInstance3D:
			(impact as GeometryInstance3D).material_override = _visual_material
		get_parent().add_child(impact)
		impact.global_position = global_position
	finished.emit()
	queue_free()

@tool
class_name MultiMeshScatter
extends MultiMeshInstance3D
## Scatters many copies of one small mesh (flowers, grass tufts, pebbles)
## inside a rectangle as a single MultiMesh = one draw call.
##
## Placement is deterministic (seeded), rebuilt at load time and never saved
## into the scene file, so .tscn files stay small and diff-friendly.

@export var mesh: Mesh:
	set(value):
		mesh = value
		_rebuild_if_ready()
@export_range(0, 20000) var count: int = 200:
	set(value):
		count = value
		_rebuild_if_ready()
@export var area_size: Vector2 = Vector2(40.0, 40.0):
	set(value):
		area_size = value
		_rebuild_if_ready()
@export var random_seed: int = 1:
	set(value):
		random_seed = value
		_rebuild_if_ready()
@export var scale_range: Vector2 = Vector2(0.7, 1.3):
	set(value):
		scale_range = value
		_rebuild_if_ready()
@export var y_offset: float = 0.0:
	set(value):
		y_offset = value
		_rebuild_if_ready()
## Optional per-instance tint. Material must enable vertex_color_use_as_albedo.
@export var palette: PackedColorArray = []:
	set(value):
		palette = value
		_rebuild_if_ready()
## Optional empty rectangle in the centre (e.g. a ring of background trees
## around the playable area). Zero = no hole.
@export var hole_size: Vector2 = Vector2.ZERO:
	set(value):
		hole_size = value
		_rebuild_if_ready()
## Keep-out zones in local space: x, z = centre, y = radius (paths, ponds, houses).
@export var exclusion_circles: PackedVector3Array = []:
	set(value):
		exclusion_circles = value
		_rebuild_if_ready()


func _ready() -> void:
	rebuild()


func _validate_property(property: Dictionary) -> void:
	# Generated data: show it in the editor but never write it to disk.
	if property.name == "multimesh":
		property.usage &= ~PROPERTY_USAGE_STORAGE


func rebuild() -> void:
	if mesh == null:
		multimesh = null
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var transforms: Array[Transform3D] = []
	var half := area_size * 0.5
	var attempts := 0
	while transforms.size() < count and attempts < count * 4:
		attempts += 1
		var x := rng.randf_range(-half.x, half.x)
		var z := rng.randf_range(-half.y, half.y)
		if _is_in_hole(x, z) or _is_excluded(x, z):
			continue
		var s := rng.randf_range(scale_range.x, scale_range.y)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
		transforms.append(Transform3D(basis, Vector3(x, y_offset * s, z)))

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not palette.is_empty()
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, palette[rng.randi() % palette.size()])
	multimesh = mm


func _is_in_hole(x: float, z: float) -> bool:
	return absf(x) < hole_size.x * 0.5 and absf(z) < hole_size.y * 0.5


func _is_excluded(x: float, z: float) -> bool:
	for circle in exclusion_circles:
		var dx := x - circle.x
		var dz := z - circle.z
		if dx * dx + dz * dz < circle.y * circle.y:
			return true
	return false


func _rebuild_if_ready() -> void:
	if is_inside_tree():
		rebuild()

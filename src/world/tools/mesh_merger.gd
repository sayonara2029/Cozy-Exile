class_name MeshMerger
extends Node
## Load-time draw-call reducer. Merges MeshInstance3D nodes that never move
## relative to each other and share the same material + shadow setting into a
## single MeshInstance3D (one draw call, one shadow caster, one outline pass).
##
## Put it as a child of the node that owns the parts. Targets are paths
## relative to that parent; empty = all direct MeshInstance3D children.
## Only list rigid parts: anything animated on its own must stay separate.
## The first part of each group becomes `<merged_prefix><n>` holding the merged
## mesh; the other parts are freed.
## Runs in _ready, i.e. before the parent's _ready, so parents that collect
## meshes (EnemyVisual, PlayerVisual) already see the merged result.

@export var targets: Array[NodePath] = []
@export var merged_prefix: String = "Merged"


func _ready() -> void:
	merge()


## Returns the number of MeshInstance3D nodes removed by merging.
func merge() -> int:
	var owner_node := get_parent() as Node3D
	if owner_node == null:
		return 0
	var parts: Array[MeshInstance3D] = []
	if targets.is_empty():
		for child in owner_node.get_children():
			if child is MeshInstance3D:
				parts.append(child)
	else:
		for path in targets:
			var mi := owner_node.get_node_or_null(path) as MeshInstance3D
			if mi:
				parts.append(mi)

	# Group by (material, shadow mode) so lighting, outlines and shadows stay identical.
	var groups := {}
	for mi in parts:
		if mi.mesh == null or mi.mesh.get_surface_count() != 1:
			continue
		var material := mi.get_active_material(0)
		var key := "%d:%d" % [material.get_instance_id() if material else 0, mi.cast_shadow]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(mi)

	var removed := 0
	var index := 0
	var to_local := owner_node.global_transform.affine_inverse()
	for key in groups:
		var group: Array = groups[key]
		if group.size() < 2:
			continue
		var tool := SurfaceTool.new()
		for mi in group:
			var part := mi as MeshInstance3D
			tool.append_from(part.mesh, 0, to_local * part.global_transform)
		# The parent is still setting up its children, so nodes cannot be added or
		# removed here: the first part becomes the merged mesh, the others are freed.
		var keep := group[0] as MeshInstance3D
		var material := keep.get_active_material(0)
		var merged := tool.commit()
		merged.surface_set_material(0, material)
		keep.material_override = null
		keep.mesh = merged
		keep.global_transform = owner_node.global_transform
		keep.name = "%s%d" % [merged_prefix, index]
		index += 1
		for i in range(1, group.size()):
			var part := group[i] as MeshInstance3D
			part.visible = false
			part.queue_free()
			removed += 1
	return removed

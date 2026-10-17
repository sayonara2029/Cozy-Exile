extends Node3D
## Composition root for the current play session.
##
## Only wires scenes together (spawn point, camera target, debug lines).
## It holds no gameplay rules; those live in components and future systems.

@onready var level: Node3D = $Level
@onready var player: Player = $Player
@onready var camera_rig: ARPGCamera = $ARPGCamera
@onready var debug_overlay: DebugOverlay = $DebugOverlay


func _ready() -> void:
	var spawn := level.get_node_or_null(^"PlayerSpawn") as Marker3D
	if spawn:
		player.teleport_to(spawn.global_position)
	else:
		push_warning("Level has no PlayerSpawn marker; player stays at its default position.")

	camera_rig.target = player
	camera_rig.snap_to_target()
	_register_debug_watches()


func _register_debug_watches() -> void:
	debug_overlay.watch("Player", func() -> String:
		var p := player.global_position
		return "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z])
	debug_overlay.watch("Speed", func() -> String:
		return "%.2f m/s" % player.movement.get_horizontal_speed(player))
	debug_overlay.watch("Zoom", func() -> String:
		return "%.1f m" % camera_rig.target_distance)
	debug_overlay.watch("Player HP", func() -> String:
		return "%d / %d" % [roundi(player.health.current_health), roundi(player.health.max_health)])
	debug_overlay.watch("Enemies", func() -> int:
		return get_tree().get_node_count_in_group(&"enemies"))
	debug_overlay.watch("Projectiles", func() -> int:
		return get_tree().get_node_count_in_group(&"projectiles"))

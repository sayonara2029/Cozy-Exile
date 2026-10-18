extends Node3D
## Composition root for the current play session.
##
## Only wires scenes together (spawn point, camera target, camera shake,
## placeholder respawn, debug lines). Gameplay rules live in components.

## Placeholder until a real defeat flow exists: revive at spawn after this delay.
const RESPAWN_DELAY := 1.5

var _spawn_position: Vector3

@onready var level: Node3D = $Level
@onready var player: Player = $Player
@onready var camera_rig: ARPGCamera = $ARPGCamera
@onready var debug_overlay: DebugOverlay = $DebugOverlay
@onready var skill_slot: SkillSlot = $SkillHud/SkillSlot


func _ready() -> void:
	var spawn := level.get_node_or_null(^"PlayerSpawn") as Marker3D
	if spawn:
		_spawn_position = spawn.global_position
	else:
		push_warning("Level has no PlayerSpawn marker; player stays at its default position.")
		_spawn_position = player.global_position
	player.teleport_to(_spawn_position)

	camera_rig.target = player
	camera_rig.snap_to_target()
	_connect_combat_feedback()
	skill_slot.bind(player.skills)
	_register_debug_watches()


func _connect_combat_feedback() -> void:
	player.health.damaged.connect(func(_info: DamageInfo, applied: float) -> void:
		if applied > 0.0:
			camera_rig.shake(0.12, 0.22))
	player.downed.connect(_on_player_downed)
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Enemy
		if enemy:
			enemy.defeated.connect(func(_e: Enemy) -> void: camera_rig.shake(0.04, 0.12))


func _on_player_downed() -> void:
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	player.revive_at(_spawn_position)
	camera_rig.snap_to_target()


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
	debug_overlay.watch("Skill", func() -> String:
		var s := player.skills
		if not s.has_skill():
			return "none"
		var state := "ready" if s.is_ready() else "cooldown %.2f s" % s.get_cooldown_left()
		return "%s (%s)  dmg %.0f  cd %.2f s" % [s.skill.display_name, state, s.skill.base_damage, s.skill.cooldown])

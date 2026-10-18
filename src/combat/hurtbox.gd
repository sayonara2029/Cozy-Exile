class_name Hurtbox
extends Area3D
## The part of an actor that can be hit. Attacks (projectiles, future melee
## or AoE shapes) find a Hurtbox and call receive_hit(); the hurtbox forwards
## the damage to its HealthComponent.
##
## Factions are separated by physics layers, not code: enemy hurtboxes sit on
## the "enemy_hurtboxes" layer, player hurtboxes on "player_hurtboxes", and
## each attack only masks the layer it is allowed to hit.

## Emitted for every accepted hit, before damage is applied.
signal hit_received(info: DamageInfo)

@export var health: HealthComponent
## The actor this hurtbox belongs to; attacks ignore hits on their own source.
@export var actor: Node
## After an accepted hit, ignore further hits for this long (player i-frames).
## 0 = always hittable (enemies).
@export var invulnerable_time: float = 0.0

var _invulnerable_left: float = 0.0


func _ready() -> void:
	# Hurtboxes are only detected, they never scan for others.
	monitoring = false
	set_physics_process(false)


func can_be_hit() -> bool:
	return monitorable and _invulnerable_left <= 0.0 and (health == null or not health.is_dead())


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


func receive_hit(info: DamageInfo) -> void:
	if not can_be_hit():
		return
	if invulnerable_time > 0.0:
		_invulnerable_left = invulnerable_time
		set_physics_process(true)
	hit_received.emit(info)
	if health:
		health.take_damage(info)


## Re-enables a disabled hurtbox and clears i-frames (respawn).
func enable() -> void:
	_invulnerable_left = 0.0
	set_deferred(&"monitorable", true)


func _physics_process(delta: float) -> void:
	_invulnerable_left -= delta
	if _invulnerable_left <= 0.0:
		_invulnerable_left = 0.0
		set_physics_process(false)


## Stops this hurtbox from being found (e.g. on death). Safe during physics callbacks.
func disable() -> void:
	set_deferred(&"monitorable", false)

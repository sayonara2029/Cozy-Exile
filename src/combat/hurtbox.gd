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


func _ready() -> void:
	# Hurtboxes are only detected, they never scan for others.
	monitoring = false


func can_be_hit() -> bool:
	return monitorable and (health == null or not health.is_dead())


func receive_hit(info: DamageInfo) -> void:
	if not can_be_hit():
		return
	hit_received.emit(info)
	if health:
		health.take_damage(info)


## Stops this hurtbox from being found (e.g. on death). Safe during physics callbacks.
func disable() -> void:
	set_deferred(&"monitorable", false)

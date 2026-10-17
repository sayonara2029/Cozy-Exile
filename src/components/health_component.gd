class_name HealthComponent
extends Node
## Reusable hit points for any actor (player, enemies, destructible props).
##
## Owns only the numbers and emits signals; what happens on hit/death
## (feedback, despawn, game over) is decided by whoever listens.

signal health_changed(current: float, maximum: float)
## applied = damage actually removed (after clamping to remaining health).
signal damaged(info: DamageInfo, applied: float)
signal healed(amount: float)
signal died(info: DamageInfo)

@export var max_health: float = 100.0

var current_health: float = 0.0


func _ready() -> void:
	current_health = max_health


func is_dead() -> bool:
	return current_health <= 0.0


## Applies damage and returns the amount actually applied (0 if already dead).
## Safe to call many times in the same frame: only the first lethal hit emits died.
func take_damage(info: DamageInfo) -> float:
	if info == null or info.amount <= 0.0 or is_dead():
		return 0.0
	# Future: resistances / mitigation by info.damage_type would adjust the amount here.
	var applied := minf(info.amount, current_health)
	current_health -= applied
	damaged.emit(info, applied)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		current_health = 0.0
		died.emit(info)
	return applied


## Restores health (not above max). Dead actors cannot be healed. Returns amount healed.
func heal(amount: float) -> float:
	if amount <= 0.0 or is_dead():
		return 0.0
	var healed_amount := minf(amount, max_health - current_health)
	if healed_amount <= 0.0:
		return 0.0
	current_health += healed_amount
	healed.emit(healed_amount)
	health_changed.emit(current_health, max_health)
	return healed_amount

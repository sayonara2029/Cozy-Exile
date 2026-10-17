class_name DamageInfo
extends RefCounted
## One packet of damage travelling from an attacker to a target.
##
## Kept as plain data so future systems can build or modify it before it is
## applied: skill modifiers (amount, type), evolutions (extra effects),
## resistances (in HealthComponent / a future stats step).

## Damage types. Only MAGIC exists in M03. Add new types by APPENDING to the end
## (e.g. PHYSICAL, FIRE, COLD, LIGHTNING, NATURE) so saved/exported values of
## existing entries never change meaning.
enum Type { MAGIC }

var amount: float = 0.0
var damage_type: Type = Type.MAGIC
## The actor that caused the damage (may be freed later: check is_instance_valid).
var source: Node = null
## World-space point of impact and travel direction (used for feedback/knockback).
var hit_position: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.ZERO


func _init(p_amount: float = 0.0, p_source: Node = null, p_type: Type = Type.MAGIC) -> void:
	amount = p_amount
	source = p_source
	damage_type = p_type


static func type_name(type: Type) -> String:
	return String(Type.keys()[type]).to_lower()

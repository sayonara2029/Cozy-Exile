class_name Enemy
extends CharacterBody3D
## Generic enemy actor glue. Each tick: brain decides -> movement moves.
## Melee timing, damage and feedback live in their own components; this
## script only connects them.
##
## Tuning lives on the components (single source of truth):
##   max_health     -> HealthComponent.max_health
##   move_speed     -> MovementComponent.move_speed
##   detection_range, attack_range -> EnemyBrain
##   attack_damage, attack_cooldown -> MeleeAttack (damage, cooldown)

signal defeated(enemy: Enemy)

## Knock-back speed added when hit (fades through MovementComponent deceleration).
@export var knockback_impulse: float = 4.0

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var movement: MovementComponent = $MovementComponent
@onready var brain: EnemyBrain = $EnemyBrain
@onready var melee: MeleeAttackComponent = $MeleeAttack
@onready var visual: EnemyVisual = $Visual
@onready var _collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group(&"enemies")
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	melee.windup_started.connect(visual.play_windup)
	melee.struck.connect(func(_hits: int) -> void: visual.play_strike())


func _physics_process(delta: float) -> void:
	movement.move(self, brain.update(delta), delta)


func is_alive() -> bool:
	return not health.is_dead()


func _on_damaged(info: DamageInfo, applied: float) -> void:
	visual.play_hit(info, applied)
	movement.apply_impulse(self, info.direction * knockback_impulse)


func _on_died(_info: DamageInfo) -> void:
	remove_from_group(&"enemies")
	set_physics_process(false)
	brain.stop()
	hurtbox.disable()
	_collision.set_deferred(&"disabled", true)
	defeated.emit(self)
	await visual.play_death()
	queue_free()

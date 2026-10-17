class_name Enemy
extends CharacterBody3D
## Generic enemy actor glue: connects Health -> feedback and Health -> death.
## No AI in M03 (enemies stand still). A future brain component would feed a
## MovementComponent the same way the player's input component does.

signal defeated(enemy: Enemy)

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visual: EnemyVisual = $Visual
@onready var _collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group(&"enemies")
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func is_alive() -> bool:
	return not health.is_dead()


func _on_damaged(info: DamageInfo, applied: float) -> void:
	visual.play_hit(info, applied)


func _on_died(_info: DamageInfo) -> void:
	remove_from_group(&"enemies")
	hurtbox.disable()
	_collision.set_deferred(&"disabled", true)
	defeated.emit(self)
	await visual.play_death()
	queue_free()

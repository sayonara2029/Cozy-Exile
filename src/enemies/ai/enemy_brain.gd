class_name EnemyBrain
extends Node
## Minimal reusable enemy AI. Decides *what* to do; the actor applies it.
##
##   IDLE --target within detection_range--> CHASE
##   CHASE --within attack_range--> ATTACK (melee wind-up/strike/recovery)
##   ATTACK --finished--> CHASE, or COOLDOWN if still in range but not ready
##   any --target lost / beyond detection_range + lose_margin / dead--> IDLE
##
## Call update() once per physics tick; it returns the direction to move in
## (zero while idle, attacking or waiting), which the actor feeds to its
## MovementComponent. Targets are found by group, never by node path.

signal state_changed(previous: State, current: State)

enum State { IDLE, CHASE, ATTACK, COOLDOWN }

@export var body: Node3D
@export var melee: MeleeAttackComponent
@export var target_group: StringName = &"player"
@export var detection_range: float = 7.0
## Extra distance before a chasing enemy gives up (stops flicker at the edge).
@export var lose_margin: float = 3.0
## Centre-to-centre distance at which the enemy stops and attacks.
@export var attack_range: float = 1.3

var state: State = State.IDLE
var target: Node3D = null


func update(_delta: float) -> Vector3:
	_refresh_target()
	var to_target := Vector3.ZERO
	var distance := INF
	if target:
		to_target = target.global_position - body.global_position
		to_target.y = 0.0
		distance = to_target.length()

	match state:
		State.IDLE:
			if target and distance <= detection_range:
				_set_state(State.CHASE)
		State.CHASE:
			if _lost(distance):
				_set_state(State.IDLE)
			elif distance <= attack_range:
				_try_attack(to_target)
		State.COOLDOWN:
			if _lost(distance):
				_set_state(State.IDLE)
			elif distance > attack_range * 1.2:
				_set_state(State.CHASE)
			else:
				_try_attack(to_target)
		State.ATTACK:
			if not melee.is_attacking():
				_set_state(State.CHASE)

	if state == State.CHASE and distance > attack_range * 0.9:
		return to_target / distance
	return Vector3.ZERO


## Stop everything (actor died / disabled).
func stop() -> void:
	if melee:
		melee.cancel()
	target = null
	_set_state(State.IDLE)


func _try_attack(to_target: Vector3) -> void:
	if melee and melee.start_attack(to_target):
		_set_state(State.ATTACK)
	else:
		_set_state(State.COOLDOWN)


func _lost(distance: float) -> bool:
	return target == null or distance > detection_range + lose_margin


func _refresh_target() -> void:
	if target and is_instance_valid(target) and _is_alive(target):
		return
	target = null
	var candidate := get_tree().get_first_node_in_group(target_group) as Node3D
	if candidate and _is_alive(candidate):
		target = candidate


func _is_alive(node: Node) -> bool:
	return not node.has_method(&"is_alive") or node.call(&"is_alive")


func _set_state(next: State) -> void:
	if next == state:
		return
	var previous := state
	state = next
	state_changed.emit(previous, next)

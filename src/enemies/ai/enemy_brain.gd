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
##
## Separation (M06): awake brains push gently away from nearby brains so a pack
## spreads around the player instead of stacking. Neighbours come from a static
## list kept by the class itself: no manager, no per-tick allocations.

signal state_changed(previous: State, current: State)
## Presentation hooks shared by every brain (melee forwards them from its
## MeleeAttackComponent, ranged brains emit them around their telegraph/shot).
signal attack_windup(duration: float)
## hits = targets damaged (melee) / 1 if a projectile was fired, else 0 (ranged).
signal attack_released(hits: int)

enum State { IDLE, CHASE, ATTACK, COOLDOWN }

@export var body: Node3D
@export var melee: MeleeAttackComponent
@export var target_group: StringName = &"player"
@export var detection_range: float = 7.0
## Extra distance before a chasing enemy gives up (stops flicker at the edge).
@export var lose_margin: float = 3.0
## Centre-to-centre distance at which the enemy stops and attacks.
@export var attack_range: float = 1.3

@export_group("Separation")
## Neighbours closer than this (centre to centre) push each other apart.
@export var separation_radius: float = 1.4
## Strength while chasing (added to the chase direction before normalising).
@export var separation_weight: float = 1.2
## Gentler nudge while standing still (attacking / waiting) so packs spread out.
@export var idle_separation_weight: float = 0.8

# Every live brain, for separation. Maintained in _enter_tree/_exit_tree.
static var _brains: Array[EnemyBrain] = []

var state: State = State.IDLE
var target: Node3D = null

var _stopped: bool = false


func _enter_tree() -> void:
	_brains.append(self)


func _ready() -> void:
	if melee:
		melee.windup_started.connect(func(d: float) -> void: attack_windup.emit(d))
		melee.struck.connect(func(h: int) -> void: attack_released.emit(h))


func _exit_tree() -> void:
	_brains.erase(self)


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

	if state == State.IDLE:
		return Vector3.ZERO
	var separation := _separation()
	if state == State.CHASE and distance > attack_range * 0.9:
		var steer := to_target / distance + separation * separation_weight
		return steer.normalized() if steer.length_squared() > 1.0 else steer
	if state == State.ATTACK:
		return Vector3.ZERO  # committed: hold still during wind-up / strike
	# Waiting in range: a gentle push, ignored when tiny (prevents jitter).
	var nudge := separation * idle_separation_weight
	return nudge if nudge.length_squared() > 0.0036 else Vector3.ZERO


## Stop everything (actor died / disabled).
func stop() -> void:
	_stopped = true
	if melee:
		melee.cancel()
	target = null
	_set_state(State.IDLE)


## Sum of pushes away from neighbours inside separation_radius (0..~1 each,
## stronger when closer). Flat on the ground plane.
func _separation() -> Vector3:
	var push := Vector3.ZERO
	var here := body.global_position
	for other in _brains:
		if other == self or other._stopped or other.body == null:
			continue
		var away := here - other.body.global_position
		away.y = 0.0
		var d2 := away.length_squared()
		if d2 >= separation_radius * separation_radius:
			continue
		if d2 < 0.0001:
			# Exactly on top of each other: split deterministically by instance id.
			away = Vector3.RIGHT if get_instance_id() > other.get_instance_id() else Vector3.LEFT
			d2 = 0.0001
		var d := sqrt(d2)
		push += away / d * (1.0 - d / separation_radius)
	return push


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

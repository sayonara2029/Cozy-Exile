class_name RangedEnemyBrain
extends EnemyBrain
## Ranged variant of EnemyBrain. Reuses target lookup, separation, states and
## signals; only the decision step differs:
##
##   IDLE --target within detection_range--> CHASE ("maintain range")
##   CHASE: walk in / back off until inside the preferred band, then if the
##          skill is ready -> ATTACK
##   ATTACK: hold still for telegraph_time (attack_windup signal), then aim at
##           the target's *current* position and cast once (attack_released)
##   COOLDOWN: hold still for recovery_time, then back to CHASE (reposition)
##   any --target lost / dead--> IDLE
##
## Firing goes through a SkillController, so damage, speed, cooldown and look
## come from a SkillData and the projectile/hurtbox pipeline is the player's.

@export var skill: SkillController
## Distance the enemy tries to keep from its target (centre to centre).
@export var preferred_range: float = 6.0
## Acceptable band around preferred_range. Movement starts only when the
## distance leaves the outer band and stops once back inside the inner half,
## so the enemy does not shuffle back and forth at the edge.
@export var range_tolerance: float = 1.5
## Never attack (only back off) when the target is closer than this.
@export var min_attack_range: float = 2.5
@export var telegraph_time: float = 0.6
@export var recovery_time: float = 0.45

var _timer: float = 0.0
var _repositioning: bool = true


func update(delta: float) -> Vector3:
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
				_repositioning = true
				_set_state(State.CHASE)
		State.CHASE:
			if _lost(distance):
				_set_state(State.IDLE)
			elif _in_attack_band(distance) and skill and skill.is_ready():
				_timer = telegraph_time
				_set_state(State.ATTACK)
				attack_windup.emit(telegraph_time)
		State.ATTACK:
			if _lost(distance):
				_set_state(State.IDLE)
			else:
				_timer -= delta
				if _timer <= 0.0:
					# Aim where the target is now: moving during the telegraph dodges.
					var fired := skill != null and skill.try_cast(to_target)
					attack_released.emit(1 if fired else 0)
					_timer = recovery_time
					_set_state(State.COOLDOWN)
		State.COOLDOWN:
			if _lost(distance):
				_set_state(State.IDLE)
			else:
				_timer -= delta
				if _timer <= 0.0:
					_repositioning = not _in_attack_band(distance)
					_set_state(State.CHASE)

	if state != State.CHASE or distance == INF:
		return Vector3.ZERO
	return _keep_range(to_target, distance)


## Movement while "maintaining range": approach or back off with hysteresis.
func _keep_range(to_target: Vector3, distance: float) -> Vector3:
	var outer := range_tolerance
	var inner := range_tolerance * 0.5
	var offset := distance - preferred_range
	if absf(offset) > outer:
		_repositioning = true
	elif absf(offset) < inner:
		_repositioning = false
	var steer := Vector3.ZERO
	if _repositioning:
		var dir := to_target / maxf(distance, 0.001)
		steer = dir if offset > 0.0 else -dir
	steer += _separation() * separation_weight
	if steer.length_squared() < 0.0036:
		return Vector3.ZERO
	return steer.normalized() if steer.length_squared() > 1.0 else steer


func _in_attack_band(distance: float) -> bool:
	return distance >= min_attack_range and absf(distance - preferred_range) <= range_tolerance


func stop() -> void:
	super.stop()
	_timer = 0.0

class_name PlayerModel
extends Node3D
## Procedural idle/walk animation for the primitive chibi model.
##
## Presentation only. The rest of the game talks to it through two calls:
##   set_locomotion(speed_ratio)  0 = standing, 1 = full walk speed
##   pulse(strength)              small squash "pop" (start/stop, future hits)
## A future rigged GLB model can replace this scene as long as it offers the
## same two methods, so nothing outside the Visual node has to change.
##
## Cost: a handful of rotations per physics tick, no AnimationTree, no skinning.

@export_group("Walk")
## Leg cycles per second at full speed.
@export var stride_frequency: float = 1.9
@export var leg_swing_degrees: float = 34.0
@export var arm_swing_degrees: float = 30.0
@export var body_bob_height: float = 0.07
@export var lean_degrees: float = 7.0
## How quickly idle and walk blend into each other.
@export var blend_sharpness: float = 9.0

@export_group("Idle")
@export var breath_frequency: float = 2.1
@export var breath_amount: float = 0.025
@export var head_sway_degrees: float = 3.0

@export_group("Accents")
@export var pulse_decay: float = 5.0
@export var gem_spin_speed: float = 1.4

var _target_walk: float = 0.0
var _walk: float = 0.0
var _phase: float = 0.0
var _time: float = 0.0
var _pulse: float = 0.0

@onready var _body: Node3D = $Body
@onready var _torso: Node3D = $Body/Torso
@onready var _head: Node3D = $Body/Head
@onready var _arm_left: Node3D = $Body/ArmLeft
@onready var _arm_right: Node3D = $Body/ArmRight
@onready var _leg_left: Node3D = $Body/LegLeft
@onready var _leg_right: Node3D = $Body/LegRight
@onready var _scarf_tail: Node3D = $Body/Torso/ScarfTail
@onready var _gem: Node3D = $Body/Head/Hat/Gem


func set_locomotion(speed_ratio: float) -> void:
	_target_walk = clampf(speed_ratio, 0.0, 1.0)


func pulse(strength: float = 1.0) -> void:
	_pulse = maxf(_pulse, strength)


func _physics_process(delta: float) -> void:
	_time += delta
	_walk = lerpf(_walk, _target_walk, 1.0 - exp(-blend_sharpness * delta))
	_phase = fmod(_phase + delta * TAU * stride_frequency * _walk, TAU)
	_pulse = move_toward(_pulse, 0.0, delta * pulse_decay)

	var idle := 1.0 - _walk
	var swing := sin(_phase)

	# Legs and arms swing in opposition.
	var leg := deg_to_rad(leg_swing_degrees) * swing * _walk
	_leg_left.rotation.x = leg
	_leg_right.rotation.x = -leg
	var arm := deg_to_rad(arm_swing_degrees) * swing * _walk
	var arm_idle := sin(_time * breath_frequency) * 0.05 * idle
	_arm_left.rotation.x = -arm + arm_idle
	_arm_right.rotation.x = arm + arm_idle

	# Two bounces per stride, small forward lean while walking.
	_body.position.y = absf(swing) * body_bob_height * _walk
	_body.rotation.x = -deg_to_rad(lean_degrees) * _walk
	_body.rotation.z = swing * 0.04 * _walk

	# Idle breathing and a gentle head sway.
	var breath := sin(_time * breath_frequency) * breath_amount * idle
	_torso.scale = Vector3(1.0 - breath * 0.5, 1.0 + breath, 1.0 - breath * 0.5)
	_head.rotation.z = sin(_time * 1.3) * deg_to_rad(head_sway_degrees) * idle
	_head.rotation.x = absf(swing) * 0.05 * _walk

	# Negative X swings the tail backwards (+Z, behind the character).
	_scarf_tail.rotation.x = -(0.2 + 0.55 * _walk + sin(_phase * 2.0) * 0.12 * _walk)

	_gem.rotation.y += delta * gem_spin_speed
	var twinkle := 1.0 + sin(_time * 3.0) * 0.08
	_gem.scale = Vector3(twinkle, twinkle, twinkle)

	# Squash-and-stretch pop on top of everything else.
	var squash := sin(_pulse * PI) * 0.09
	scale = Vector3(1.0 + squash * 0.6, 1.0 - squash, 1.0 + squash * 0.6)

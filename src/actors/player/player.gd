class_name Player
extends CharacterBody3D
## Player actor. Thin glue only: asks the input component for a direction
## and hands it to the movement component. Future systems (health, skills,
## equipment, stats) attach as sibling components, not as code in here.

@onready var input_component: PlayerInputComponent = $PlayerInputComponent
@onready var movement: MovementComponent = $MovementComponent


func _physics_process(delta: float) -> void:
	movement.move(self, input_component.get_move_direction(), delta)


## Moves the player instantly (spawn, portals) without interpolation smear.
func teleport_to(world_position: Vector3) -> void:
	global_position = world_position
	velocity = Vector3.ZERO
	reset_physics_interpolation()

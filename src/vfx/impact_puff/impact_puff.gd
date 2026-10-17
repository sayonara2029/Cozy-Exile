extends MeshInstance3D
## Tiny impact flash: grows quickly, then shrinks away and frees itself.
## Shared unshaded material, scale-only animation (no per-instance materials).

@export var max_scale: float = 1.0
@export var duration: float = 0.18


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	scale = Vector3.ONE * 0.3
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * max_scale, duration * 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3.ZERO, duration * 0.65) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

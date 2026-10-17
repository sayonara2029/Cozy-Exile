class_name DamageNumber
extends Label3D
## Floating damage number: pops up, drifts upward, fades and frees itself.
## Billboard Label3D drawn on top of the world, no particles.

@export var rise: float = 0.9
@export var duration: float = 0.7


func show_amount(world_position: Vector3, amount: float) -> void:
	global_position = world_position
	text = str(roundi(amount))
	scale = Vector3.ONE * 0.6
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ONE, duration * 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:y", world_position.y + rise, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	tween.tween_property(self, "outline_modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	tween.chain().tween_callback(queue_free)

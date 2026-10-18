class_name SkillSlot
extends Control
## One small skill indicator (not a hotbar): coloured orb, cooldown ring,
## skill name and key hint. Pops when the skill becomes ready, shakes when a
## cast is rejected. Drawn with _draw(); redraws only while something changes.

@export var radius: float = 26.0
@export var key_hint: String = "LMB / Space"
@export var background_color: Color = Color(0.13, 0.1, 0.16, 0.62)
@export var ring_color: Color = Color(1.0, 0.97, 0.9, 0.95)
@export var rejected_color: Color = Color(1.0, 0.45, 0.3, 1.0)

var _controller: SkillController
var _pop: float = 0.0
var _shake: float = 0.0
var _font: Font
var _was_cooling: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_default_font()
	set_process(false)


## Connects this slot to a caster. Call once from the composition root.
func bind(controller: SkillController) -> void:
	_controller = controller
	controller.cast.connect(func(_s: SkillData, _d: Vector3) -> void: _wake())
	controller.became_ready.connect(func(_s: SkillData) -> void:
		_pop = 1.0
		_wake())
	controller.cast_rejected.connect(func(_s: SkillData) -> void:
		_shake = 1.0
		_wake())
	queue_redraw()


func _wake() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_pop = move_toward(_pop, 0.0, delta * 4.0)
	_shake = move_toward(_shake, 0.0, delta * 5.0)
	var cooling := _controller != null and _controller.get_cooldown_ratio() > 0.0
	queue_redraw()
	if not cooling and _pop <= 0.0 and _shake <= 0.0 and not _was_cooling:
		set_process(false)
	_was_cooling = cooling


func _draw() -> void:
	if _controller == null or not _controller.has_skill():
		return
	var skill := _controller.skill
	var ratio := _controller.get_cooldown_ratio()
	var center := size * 0.5 + Vector2(sin(_shake * 40.0) * 5.0 * _shake, -10.0)
	var r := radius * (1.0 + 0.18 * sin(_pop * PI))

	draw_circle(center, r + 6.0, background_color)
	var orb := skill.color
	if ratio > 0.0:
		orb = orb.darkened(0.55)
	draw_circle(center, r, orb)
	# Cooldown: the remaining part of the ring, sweeping clockwise from the top.
	if ratio > 0.0:
		draw_arc(center, r + 3.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 32, ring_color, 3.0, true)
	if _shake > 0.0:
		draw_arc(center, r + 3.0, 0.0, TAU, 32, rejected_color * Color(1, 1, 1, _shake), 3.0, true)

	var label := skill.display_name
	var font_size := 14
	var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	draw_string_outline(_font, center + Vector2(-w * 0.5, r + 24.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, background_color)
	draw_string(_font, center + Vector2(-w * 0.5, r + 24.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ring_color)
	var hw := _font.get_string_size(key_hint, HORIZONTAL_ALIGNMENT_CENTER, -1, 11).x
	draw_string(_font, center + Vector2(-hw * 0.5, r + 39.0), key_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ring_color * Color(1, 1, 1, 0.7))

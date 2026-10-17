class_name DebugOverlay
extends CanvasLayer
## Lightweight FPS / render stats overlay. Toggle with F3.
##
## Other code adds lines through watch(), so the overlay never needs to know
## about the player, camera or any future system.

@export var refresh_interval: float = 0.25
@export var start_visible: bool = true

var _watch_labels: PackedStringArray = []
var _watch_getters: Array[Callable] = []
var _elapsed: float = 0.0

@onready var _panel: Control = $Panel
@onready var _label: Label = %StatsLabel


func _ready() -> void:
	# Hide the panel, not the layer: the layer must keep receiving F3.
	_panel.visible = start_visible
	_refresh()


func is_shown() -> bool:
	return _panel.visible


## Adds a live line. getter takes no arguments and returns anything printable.
func watch(label: String, getter: Callable) -> void:
	_watch_labels.append(label)
	_watch_getters.append(getter)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_debug"):
		_panel.visible = not _panel.visible
		if _panel.visible:
			_refresh()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _panel.visible:
		return
	_elapsed += delta
	if _elapsed >= refresh_interval:
		_elapsed = 0.0
		_refresh()


func _refresh() -> void:
	var lines := PackedStringArray()
	lines.append("FPS  %d   (%.2f ms)" % [
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
	])
	lines.append("Draw calls  %d   Objects  %d" % [
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
	])
	lines.append("Primitives  %d" % Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	lines.append("Memory  %.1f MB   VRAM  %.1f MB" % [
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
	])
	lines.append("Renderer  %s" % RenderingServer.get_current_rendering_method())
	for i in _watch_labels.size():
		lines.append("%s  %s" % [_watch_labels[i], str(_watch_getters[i].call())])
	lines.append("[F3] hide")
	_label.text = "\n".join(lines)

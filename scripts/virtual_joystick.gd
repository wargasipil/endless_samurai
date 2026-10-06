extends Control

const RADIUS := 90.0
const KNOB_RADIUS := 40.0

var active_touch: int = -1
var center: Vector2 = Vector2.ZERO
var knob_offset: Vector2 = Vector2.ZERO

signal direction_changed(dir: Vector2)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(RADIUS * 2.0, RADIUS * 2.0)
	center = size * 0.5

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		center = size * 0.5
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1:
			active_touch = event.index
			_update_knob(event.position)
		elif not event.pressed and event.index == active_touch:
			_reset()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_update_knob(event.position)
	elif event is InputEventMouseButton:
		if event.pressed and active_touch == -1:
			active_touch = 0
			_update_knob(event.position)
		elif not event.pressed and active_touch == 0:
			_reset()
	elif event is InputEventMouseMotion and active_touch == 0:
		_update_knob(event.position)

func _update_knob(pos: Vector2) -> void:
	var delta := pos - center
	if delta.length() > RADIUS:
		delta = delta.normalized() * RADIUS
	knob_offset = delta
	direction_changed.emit(delta / RADIUS)
	queue_redraw()

func _reset() -> void:
	active_touch = -1
	knob_offset = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)
	queue_redraw()

func _draw() -> void:
	draw_circle(center, RADIUS, Color(1, 1, 1, 0.08))
	draw_arc(center, RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 2.0)
	draw_circle(center + knob_offset, KNOB_RADIUS, Color(1, 1, 1, 0.25))
	draw_arc(center + knob_offset, KNOB_RADIUS, 0.0, TAU, 24, Color(1, 1, 1, 0.6), 2.0)

extends Control

signal direction_changed(dir: Vector2)

const TEX_DEFAULT := preload("res://assets/dpad/dpad_default.png")
const TEX_UP      := preload("res://assets/dpad/dpad_pressed_up.png")
const TEX_RIGHT   := preload("res://assets/dpad/dpad_pressed_right.png")
const TEX_DOWN    := preload("res://assets/dpad/dpad_pressed_down.png")

const DEAD_ZONE_RATIO := 0.18

@onready var base: TextureRect = $Base

var active_touch: int = -1
var current_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1:
			active_touch = event.index
			_update(event.position)
		elif not event.pressed and event.index == active_touch:
			_reset()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_update(event.position)
	elif event is InputEventMouseButton:
		if event.pressed and active_touch == -1:
			active_touch = 0
			_update(event.position)
		elif not event.pressed and active_touch == 0:
			_reset()
	elif event is InputEventMouseMotion and active_touch == 0:
		_update(event.position)

func _update(pos: Vector2) -> void:
	var center := size * 0.5
	var delta := pos - center
	var dead: float = minf(size.x, size.y) * 0.5 * DEAD_ZONE_RATIO
	if delta.length() < dead:
		_set_dir(Vector2.ZERO)
		return
	if absf(delta.x) >= absf(delta.y):
		_set_dir(Vector2(signf(delta.x), 0.0))
	else:
		_set_dir(Vector2(0.0, signf(delta.y)))

func _reset() -> void:
	active_touch = -1
	_set_dir(Vector2.ZERO)

func _set_dir(dir: Vector2) -> void:
	if dir == current_dir:
		return
	current_dir = dir
	_refresh_tex()
	direction_changed.emit(dir)

func _refresh_tex() -> void:
	if base == null:
		return
	if current_dir == Vector2.ZERO:
		base.texture = TEX_DEFAULT
		base.flip_h = false
	elif current_dir.y < 0.0:
		base.texture = TEX_UP
		base.flip_h = false
	elif current_dir.y > 0.0:
		base.texture = TEX_DOWN
		base.flip_h = false
	elif current_dir.x > 0.0:
		base.texture = TEX_RIGHT
		base.flip_h = false
	else:
		base.texture = TEX_RIGHT
		base.flip_h = true

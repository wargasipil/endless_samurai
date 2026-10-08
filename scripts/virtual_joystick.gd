extends Control
## Origami virtual joystick (Godot 4).
## Attach to a Control node, drag joystick_sheet.svg into "Sheet",
## and give the Control a square size, for example 300 x 300.

## Emitted whenever output changes; x and y go from -1 to 1.
signal direction_changed(dir: Vector2)

@export var sheet: Texture2D
@export_range(0.1, 0.5) var max_distance := 0.3   ## how far the knob can move (part of the size)
@export_range(0.0, 0.9) var deadzone := 0.15      ## ignore tiny thumb movements
@export_range(0.0, 1.0) var idle_alpha := 0.6     ## how see-through it is when not touched
@export var use_actions := true                    ## also press the move_* input actions
@export var action_left := "move_left"
@export var action_right := "move_right"
@export var action_up := "move_up"
@export var action_down := "move_down"

## Read this from your player if you like: x and y go from -1 to 1.
var output := Vector2.ZERO

var _touch := -1
var _textures: Array[AtlasTexture] = []   # base_idle, base_active, knob_idle, knob_pressed
var _base: TextureRect
var _knob: TextureRect


func _ready() -> void:
	if sheet == null:
		push_warning("Drag joystick_sheet.svg into the Sheet field.")
		return
	var cell_width := sheet.get_width() / 4.0
	for i in 4:
		var t := AtlasTexture.new()
		t.atlas = sheet
		t.region = Rect2(i * cell_width, 0, cell_width, sheet.get_height())
		_textures.append(t)
	_base = _add_layer(_textures[0])
	_knob = _add_layer(_textures[2])
	modulate.a = idle_alpha


func _add_layer(tex: Texture2D) -> TextureRect:
	var layer := TextureRect.new()
	layer.texture = tex
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return layer


func _input(event: InputEvent) -> void:
	if _knob == null:
		return
	if event is InputEventScreenTouch:
		# _input sees every touch, so skip new ones while hidden (e.g. --demo hides the controls)
		if event.pressed and _touch == -1 and is_visible_in_tree() and get_global_rect().has_point(event.position):
			_touch = event.index
			_set_active(true)
			_update(event.position)
		elif not event.pressed and event.index == _touch:
			_touch = -1
			_set_active(false)
			_update(get_global_rect().get_center())
	elif event is InputEventScreenDrag and event.index == _touch:
		_update(event.position)


func _update(finger: Vector2) -> void:
	var max_px := size.x * max_distance
	var offset := (finger - get_global_rect().get_center()).limit_length(max_px)
	_knob.position = offset
	var v := offset / max_px
	var last := output
	output = Vector2.ZERO if v.length() < deadzone else v
	if output != last:
		direction_changed.emit(output)
	if use_actions:
		_press(action_left, maxf(-output.x, 0.0))
		_press(action_right, maxf(output.x, 0.0))
		_press(action_up, maxf(-output.y, 0.0))
		_press(action_down, maxf(output.y, 0.0))


func _press(action: String, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _set_active(on: bool) -> void:
	_base.texture = _textures[1] if on else _textures[0]
	_knob.texture = _textures[3] if on else _textures[2]
	modulate.a = 1.0 if on else idle_alpha

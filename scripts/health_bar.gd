extends Control
class_name HealthBar
## Flat minimal health bar built from healthbar_flat.png (Godot 4)

## Drag healthbar_flat.png (or the @2x file) here in the Inspector
@export var sheet: Texture2D
## Set to 2 if you use healthbar_flat@2x.png
@export var sheet_scale: int = 1
@export var max_health: float = 100.0

# Positions in the 1x sprite sheet (the script multiplies them by sheet_scale)
const CELL := Vector2(128, 32)       # size of one cell
const FILL_POS := Vector2(14, 12)    # where the fill starts inside a cell
const FILL_SIZE := Vector2(100, 8)   # size of the fill area
const EMPTY := Vector2(256, 64)      # hp_0 cell (frame + empty slot)
const HIT := Vector2(384, 64)        # hp_hit cell (white flash)
const GREEN := Vector2(0, 96)        # fill_green cell
const YELLOW := Vector2(128, 96)     # fill_yellow cell
const RED := Vector2(256, 96)        # fill_red cell
const TRAIL := Vector2(384, 96)      # fill_trail cell

var health: float
var _trail_bar: TextureProgressBar
var _fill_bar: TextureProgressBar
var _tex_green: AtlasTexture
var _tex_yellow: AtlasTexture
var _tex_red: AtlasTexture
var _tex_hit: AtlasTexture
var _fill_tween: Tween
var _trail_tween: Tween
var _flash_tween: Tween


func _ready() -> void:
	if sheet == null:
		push_error("HealthBar: drag healthbar_flat.png into the Sheet property.")
		return
	health = max_health
	_tex_green = _fill_texture(GREEN)
	_tex_yellow = _fill_texture(YELLOW)
	_tex_red = _fill_texture(RED)
	_tex_hit = _fill_texture(HIT)

	# Back layer: the empty frame plus the gray trail
	_trail_bar = _make_bar()
	_trail_bar.texture_under = _cut(EMPTY, CELL)
	_trail_bar.texture_progress = _fill_texture(TRAIL)

	# Front layer: the colored fill
	_fill_bar = _make_bar()
	_fill_bar.texture_progress = _tex_green

	custom_minimum_size = CELL * sheet_scale


## Call this whenever health changes, e.g. health_bar.set_health(player_hp)
func set_health(new_health: float) -> void:
	var old_health := health
	health = clampf(new_health, 0.0, max_health)
	# Nothing changed: don't cut a running trail short
	if is_equal_approx(health, old_health):
		return

	# The fill slides quickly to the new value
	if _fill_tween:
		_fill_tween.kill()
	_fill_tween = create_tween()
	_fill_tween.tween_property(_fill_bar, "value", health, 0.15)

	if health < old_health:
		# Damage: flash white, then the gray trail slowly catches up
		_flash()
		if _trail_tween:
			_trail_tween.kill()
		_trail_tween = create_tween()
		_trail_tween.tween_interval(0.45)
		_trail_tween.tween_property(_trail_bar, "value", health, 0.6)
	else:
		# Healing: no trail needed
		if _trail_tween:
			_trail_tween.kill()
		_trail_bar.value = health
		_fill_bar.texture_progress = _color_for(health)


## Jump straight to a value with no slide, flash or trail,
## e.g. on spawn or when max health changes
func reset_health(new_health: float, new_max_health: float = max_health) -> void:
	if _fill_tween:
		_fill_tween.kill()
	if _trail_tween:
		_trail_tween.kill()
	if _flash_tween:
		_flash_tween.kill()
	max_health = new_max_health
	health = clampf(new_health, 0.0, max_health)
	for bar in [_trail_bar, _fill_bar]:
		bar.max_value = max_health
		bar.value = health
	_fill_bar.texture_progress = _color_for(health)


func _flash() -> void:
	# A tween (not an await) so back-to-back hits restart the flash cleanly
	_fill_bar.texture_progress = _tex_hit
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.1)
	_flash_tween.tween_callback(func() -> void: _fill_bar.texture_progress = _color_for(health))


func _color_for(h: float) -> AtlasTexture:
	var percent := h / max_health
	if percent > 0.5:
		return _tex_green
	elif percent > 0.25:
		return _tex_yellow
	return _tex_red


func _make_bar() -> TextureProgressBar:
	var bar := TextureProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = max_health
	bar.step = 0.01
	bar.value = max_health
	bar.texture_progress_offset = FILL_POS * sheet_scale
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	return bar


func _fill_texture(cell_pos: Vector2) -> AtlasTexture:
	return _cut(cell_pos + FILL_POS, FILL_SIZE)


func _cut(pos: Vector2, area_size: Vector2) -> AtlasTexture:
	var t := AtlasTexture.new()
	t.atlas = sheet
	t.region = Rect2(pos * sheet_scale, area_size * sheet_scale)
	return t

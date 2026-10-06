class_name CharacterModel
extends Node3D
## Wraps an imported Quaternius-style character (shared "CharacterArmature" rig).
## Plays clips by short name ("Idle", "Run", "Weapon"), lets one-shot clips finish
## before looping ones take over again, and flashes the meshes on hit.

const LOOPING := ["Idle", "Run", "Run2", "Walk", "Jump_Idle"]

@export var model_scene: PackedScene

var _anim: AnimationPlayer
var _clips := {}
var _one_shot := ""
var _meshes: Array[MeshInstance3D] = []
var _flash_mat: StandardMaterial3D
var _flash_tween: Tween

func _ready() -> void:
	if model_scene:
		set_model(model_scene)

func set_model(scene: PackedScene) -> void:
	var inst := scene.instantiate()
	add_child(inst)
	_anim = inst.find_child("AnimationPlayer", true, false)
	_clips.clear()
	for full in _anim.get_animation_list():
		var short: String = full.get_slice("|", full.get_slice_count("|") - 1)
		_clips[short] = full
		if short in LOOPING:
			_anim.get_animation(full).loop_mode = Animation.LOOP_LINEAR
	_meshes.clear()
	for m in inst.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(m)

## Plays a looping/background clip unless a one-shot clip is still running.
func play(clip: String, speed: float = 1.0, blend: float = 0.15) -> void:
	if _one_shot != "" and _anim.current_animation == _one_shot:
		return
	_one_shot = ""
	var full: String = _clips.get(clip, "")
	if full == "":
		return
	if _anim.current_animation == full:
		_anim.speed_scale = speed
		return
	_anim.speed_scale = speed
	_anim.play(full, blend)

## Plays a clip from the start and keeps it on screen until it ends.
func play_once(clip: String, speed: float = 1.0, blend: float = 0.08) -> void:
	var full: String = _clips.get(clip, "")
	if full == "":
		return
	_one_shot = full
	_anim.speed_scale = speed
	_anim.play(full, blend)
	_anim.seek(0.0, true)

func clip_length(clip: String) -> float:
	var full: String = _clips.get(clip, "")
	return _anim.get_animation(full).length if full != "" else 0.0

func flash(color: Color, duration: float = 0.18) -> void:
	if _flash_mat == null:
		_flash_mat = StandardMaterial3D.new()
		_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_mat.albedo_color = color
	for m in _meshes:
		m.material_overlay = _flash_mat
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash_mat, "albedo_color:a", 0.0, duration)
	_flash_tween.tween_callback(_clear_flash)

func _clear_flash() -> void:
	for m in _meshes:
		m.material_overlay = null

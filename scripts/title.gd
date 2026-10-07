extends Control

const MAIN_SCENE := "res://scenes/main.tscn"

func _ready() -> void:
	$Begin.pressed.connect(_begin)
	if "--demo" in OS.get_cmdline_user_args():
		call_deferred("_begin")
		return

func _begin() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	var fired := false
	if event is InputEventScreenTouch and event.pressed:
		fired = true
	elif event is InputEventMouseButton and event.pressed:
		fired = true
	elif event is InputEventKey and event.pressed:
		fired = true
	if fired:
		_begin()

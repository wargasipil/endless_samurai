extends Control

@onready var dpad: Control = $Dpad
@onready var dir_label: Label = $DirLabel

func _ready() -> void:
	dpad.direction_changed.connect(_on_dir)

func _on_dir(d: Vector2) -> void:
	var name_str := "idle"
	if d.y < 0.0: name_str = "UP"
	elif d.y > 0.0: name_str = "DOWN"
	elif d.x > 0.0: name_str = "RIGHT"
	elif d.x < 0.0: name_str = "LEFT"
	dir_label.text = "direction: (%.2f, %.2f)   [%s]" % [d.x, d.y, name_str]

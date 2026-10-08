extends CanvasLayer

signal move_vector(v: Vector2)
signal jump_pressed
signal attack_pressed

@onready var joystick: Control = $Joystick
@onready var jump_button: Button = $JumpButton
@onready var attack_button: Button = $AttackButton

func _ready() -> void:
	joystick.direction_changed.connect(func(d: Vector2) -> void: move_vector.emit(d))
	jump_button.pressed.connect(func() -> void: jump_pressed.emit())
	attack_button.pressed.connect(func() -> void: attack_pressed.emit())

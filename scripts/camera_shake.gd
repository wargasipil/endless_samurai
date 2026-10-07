extends Camera3D

var shake_time: float = 0.0
var shake_strength: float = 0.0
var _base_offset: Vector3 = Vector3.ZERO

func _ready() -> void:
	_base_offset = position

func shake(strength: float, duration: float) -> void:
	shake_strength = maxf(shake_strength, strength)
	shake_time = maxf(shake_time, duration)

func _process(delta: float) -> void:
	if shake_time > 0.0:
		shake_time -= delta
		var decay := clampf(shake_time / 0.25, 0.0, 1.0)
		position = _base_offset + Vector3(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength),
			0.0
		) * decay * 0.1
		if shake_time <= 0.0:
			position = _base_offset
			shake_strength = 0.0

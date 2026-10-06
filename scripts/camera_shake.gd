extends Camera2D

var shake_time: float = 0.0
var shake_strength: float = 0.0

func shake(strength: float, duration: float) -> void:
	shake_strength = maxf(shake_strength, strength)
	shake_time = maxf(shake_time, duration)

func _process(delta: float) -> void:
	if shake_time > 0.0:
		shake_time -= delta
		var decay := clampf(shake_time / 0.25, 0.0, 1.0)
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		) * decay
		if shake_time <= 0.0:
			offset = Vector2.ZERO
			shake_strength = 0.0

extends Camera3D
## Follows the target from a fixed high angle (ignoring jumps) and supports shake.

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0.0, 11.0, 10.5)
@export var look_height: float = 1.0
@export var follow_speed: float = 6.0

var target: Node3D
var shake_time: float = 0.0
var shake_strength: float = 0.0

func _ready() -> void:
	target = get_node_or_null(target_path)
	if target:
		global_position = _desired_position()
		look_at(global_position - offset + Vector3.UP * look_height)

func shake(strength: float, duration: float) -> void:
	shake_strength = maxf(shake_strength, strength)
	shake_time = maxf(shake_time, duration)

func _process(delta: float) -> void:
	if target:
		global_position = global_position.lerp(_desired_position(), 1.0 - exp(-follow_speed * delta))
	if shake_time > 0.0:
		shake_time -= delta
		var decay := clampf(shake_time / 0.25, 0.0, 1.0)
		h_offset = randf_range(-shake_strength, shake_strength) * decay
		v_offset = randf_range(-shake_strength, shake_strength) * decay
		if shake_time <= 0.0:
			h_offset = 0.0
			v_offset = 0.0
			shake_strength = 0.0

func _desired_position() -> Vector3:
	var p := target.global_position
	return Vector3(p.x, 0.0, p.z) + offset

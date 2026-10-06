extends Node3D
## Dresses the arena: a ring of pines (where the oni come from), boulders along the
## edge, flickering torches and the broken torii gate. Uses a fixed seed so the
## layout is identical every run.

const PINES := [
	preload("res://assets/models/pine_a.glb"),
	preload("res://assets/models/pine_b.glb"),
]
const ROCK_LARGE := preload("res://assets/models/rock_large.glb")
const PEBBLES := preload("res://assets/models/rocks.glb")
const TORCH := preload("res://assets/models/torch.glb")
const TORII := preload("res://assets/models/torii_gate.glb")

@export var forest_inner_radius: float = 22.0
@export var forest_outer_radius: float = 34.0
@export var tree_count: int = 34
@export var torch_count: int = 6
@export var torch_radius: float = 18.5
@export var layout_seed: int = 7

var _torch_lights: Array[OmniLight3D] = []
var _flames: Array[MeshInstance3D] = []
var _time: float = 0.0

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = layout_seed

	for i in tree_count:
		var a := TAU * (i + rng.randf_range(-0.35, 0.35)) / tree_count
		var r := rng.randf_range(forest_inner_radius, forest_outer_radius)
		_place(PINES[i % PINES.size()], _ring(a, r), rng.randf() * TAU, rng.randf_range(0.8, 1.25))

	for i in 9:
		var a := rng.randf() * TAU
		_place(ROCK_LARGE, _ring(a, rng.randf_range(19.5, 23.0)), rng.randf() * TAU, rng.randf_range(0.25, 0.45))

	for i in 8:
		var a := rng.randf() * TAU
		_place(PEBBLES, _ring(a, rng.randf_range(5.0, 18.0)), rng.randf() * TAU, rng.randf_range(1.5, 2.8))

	# The broken gate the samurai guards, at the far edge facing the camera.
	var gate := _place(TORII, Vector3(0.0, 0.0, -20.0), 0.0, 1.1)
	gate.rotation.z = deg_to_rad(-4.0)

	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.16
	flame_mesh.height = 0.5
	var flame_mat := StandardMaterial3D.new()
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.albedo_color = Color(1.0, 0.55, 0.15)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.5, 0.12)
	flame_mat.emission_energy_multiplier = 3.0
	flame_mesh.material = flame_mat

	for i in torch_count:
		var a := TAU * (i + 0.5) / torch_count
		var torch := _place(TORCH, _ring(a, torch_radius), 0.0, 1.0)
		torch.position.y = 0.55
		var flame := MeshInstance3D.new()
		flame.mesh = flame_mesh
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flame.position = Vector3(0.0, 2.25, 0.0)
		torch.add_child(flame)
		_flames.append(flame)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.62, 0.3)
		light.light_energy = 2.2
		light.omni_range = 8.0
		light.position = Vector3(0.0, 2.0, 0.0)
		torch.add_child(light)
		_torch_lights.append(light)

func _process(delta: float) -> void:
	_time += delta
	for i in _torch_lights.size():
		var t := _time * 9.0 + i * 1.7
		var flicker := sin(t) * 0.25 + sin(t * 2.3) * 0.15
		_torch_lights[i].light_energy = 2.2 + flicker
		_flames[i].scale = Vector3(1.0, 1.0 + flicker * 0.6, 1.0)

func _place(scene: PackedScene, pos: Vector3, yaw: float, s: float) -> Node3D:
	var n: Node3D = scene.instantiate()
	n.position = pos
	n.rotation.y = yaw
	n.scale = Vector3.ONE * s
	add_child(n)
	return n

func _ring(angle: float, radius: float) -> Vector3:
	return Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

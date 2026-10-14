class_name Arena
extends Node3D

# The origami battleground. Designed in Blender as the SamuraiArena place (D:\blender_project,
# scripts/places/samurai_arena.py) from the Origami asset library, and exported for the game by
# scripts/tools/export_samurai_arena.py there (`run.ps1 game-arena`):
#   samurai_arena.glb   every grass clump, stone, tree and prop as a node; nodes that share a mesh
#                       are drawn here as one MultiMesh per chunk (1,100 draw calls is too many for a phone)
#   samurai_arena.json  the boundary outline (random, not a circle), the colliders (circles), the key/fill
#                       lights and the sky colours
# Blender (x, y, z) is Godot (x, z, -y): the shrine stands north, at -Z, at the top of the screen.

const SCENE := preload("res://assets/environment/samurai_arena.glb")
const LAYOUT := preload("res://assets/environment/samurai_arena.json")
const CHUNK := 12.0
const NO_SHADOW := ["Grass", "Ground"]
# Tall things that can stand between the camera and the samurai (he vanished under a maple's canopy):
# they dither away when closer to the camera than he is (set_occluder_fade, from main.gd's camera).
const OCCLUDERS := ["Trees"]
const OCCLUDER_MESHES := ["Shrine"]

@export var sun: DirectionalLight3D
@export var fill: DirectionalLight3D
@export var environment: Environment

var island_radius := 21.0
var court_radius := 7.5
# the boundary, star-shaped round the centre: its points (x, z) sorted by angle
var _outline_angles: PackedFloat32Array = []
var _outline_radii: PackedFloat32Array = []
var _outline: PackedVector2Array = []
var shrine := Vector3.ZERO
# (x, 0, z) centre and radius of every collider, for spawning and steering
var obstacles: Array[Vector3] = []
var obstacle_radii: PackedFloat32Array = []
var _fade_materials: Array[StandardMaterial3D] = []
var _fade := Vector2(7.5, 10.5)

func _ready() -> void:
	add_to_group("arena")
	var data: Dictionary = LAYOUT.data
	island_radius = data["isle_r"]
	court_radius = data["court_r"]
	for q in data["play_outline"]:
		_outline.append(Vector2(q[0], q[1]))
	var pairs := []
	for q in _outline:
		pairs.append([atan2(q.y, q.x), q.length()])
	pairs.sort_custom(func(a, b): return a[0] < b[0])
	for pr in pairs:
		_outline_angles.append(pr[0])
		_outline_radii.append(pr[1])
	shrine = Vector3(data["shrine"]["x"], 0.0, data["shrine"]["z"])
	for c in data["colliders"]:
		_add_collider(Vector3(c["x"], 0.0, c["z"]), c["r"], c["h"])
	_add_wall()
	_apply_lights(data)
	var world := SCENE.instantiate()
	add_child(world)
	_batch(world)

func _add_collider(p: Vector3, r: float, h: float) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = r
	cyl.height = h
	shape.shape = cyl
	shape.position = Vector3(0.0, h * 0.5, 0.0)
	body.add_child(shape)
	body.position = p
	add_child(body)
	obstacles.append(p)
	obstacle_radii.append(r)

func _add_wall() -> void:
	# The boundary: a box along each edge of the outline, inside the rim trees.
	var body := StaticBody3D.new()
	body.name = "Boundary"
	body.collision_layer = 1
	body.collision_mask = 0
	var n := _outline.size()
	for i in n:
		var a := _outline[i]
		var b := _outline[(i + 1) % n]
		var mid := (a + b) * 0.5
		var along := b - a
		var out := mid.normalized()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(along.length() * 1.15 + 0.4, 4.0, 1.0)
		shape.shape = box
		shape.position = Vector3(mid.x + out.x * 0.5, 2.0, mid.y + out.y * 0.5)
		shape.rotation.y = -atan2(along.y, along.x)
		body.add_child(shape)
	add_child(body)

func play_radius_at(angle: float) -> float:
	# The boundary's distance from the centre in a direction (radians, atan2(z, x)).
	var n := _outline_angles.size()
	var hi := _outline_angles.bsearch(angle)
	var i0 := (hi - 1 + n) % n
	var i1 := hi % n
	var a0 := _outline_angles[i0]
	var a1 := _outline_angles[i1]
	var span := wrapf(a1 - a0, 0.0, TAU)
	var t := 0.0 if span < 1e-6 else wrapf(angle - a0, 0.0, TAU) / span
	return lerpf(_outline_radii[i0], _outline_radii[i1], clampf(t, 0.0, 1.0))

func _apply_lights(data: Dictionary) -> void:
	# Directions and colours from the place's suns; energies are set in the scene (Godot's scale differs).
	var lights: Dictionary = data["lights"]
	for pair in [[sun, lights["key"]], [fill, lights["fill"]]]:
		var light: DirectionalLight3D = pair[0]
		var l: Dictionary = pair[1]
		if light == null:
			continue
		var to_sun := Vector3(l["to_sun"][0], l["to_sun"][1], l["to_sun"][2]).normalized()
		light.basis = Basis.looking_at(-to_sun, Vector3.UP if absf(to_sun.y) < 0.99 else Vector3.FORWARD)
		light.light_color = Color(l["color"][0], l["color"][1], l["color"][2])
	if environment and environment.sky and environment.sky.sky_material is ProceduralSkyMaterial:
		var sky: ProceduralSkyMaterial = environment.sky.sky_material
		var s: Dictionary = data["sky"]
		sky.sky_top_color = Color(s["top"][0], s["top"][1], s["top"][2])
		sky.sky_horizon_color = Color(s["horizon"][0], s["horizon"][1], s["horizon"][2])
		sky.ground_horizon_color = sky.sky_horizon_color
		sky.ground_bottom_color = Color(s["middle"][0], s["middle"][1], s["middle"][2])

func _batch(root: Node) -> void:
	var groups := {}
	var inv := global_transform.affine_inverse()
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var kind := String(mi.get_parent().name)
		if kind == "Ground":
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# Godot's automatic LODs smear the per-facet vertex colours (the sand ran into the
			# grass as a blur at 720p) and smooth the facets: always draw the full mesh (2.5k faces).
			mi.lod_bias = 128.0
			# Matte paper: the default specular put a whitish sky sheen over the facet colours.
			var mat := mi.mesh.surface_get_material(0) as StandardMaterial3D
			if mat:
				mat.metallic_specular = 0.15
			continue
		var t := inv * mi.global_transform
		var key_name := mi.mesh.resource_name if mi.mesh.resource_name != "" else str(mi.mesh.get_instance_id())
		var key := "%s|%d|%d" % [key_name, floori(t.origin.x / CHUNK), floori(t.origin.z / CHUNK)]
		if not groups.has(key):
			groups[key] = {"mesh": mi.mesh, "kind": kind, "xforms": []}
		groups[key]["xforms"].append(t)
		mi.get_parent().remove_child(mi)
		mi.queue_free()
	for key in groups:
		var g: Dictionary = groups[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = g["mesh"]
		mm.instance_count = g["xforms"].size()
		for i in mm.instance_count:
			mm.set_instance_transform(i, g["xforms"][i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = String(key).replace("|", "_")
		mmi.multimesh = mm
		if g["kind"] in NO_SHADOW:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if g["kind"] in OCCLUDERS or OCCLUDER_MESHES.any(func(m): return String(key).contains(m)):
			mmi.material_override = _fade_material(g["mesh"])
		add_child(mmi)
	set_occluder_fade(_fade.x, _fade.y)

func _fade_material(mesh: Mesh) -> StandardMaterial3D:
	var src := mesh.surface_get_material(0) as StandardMaterial3D
	for m in _fade_materials:
		if m.resource_name == src.resource_name + "_fade":
			return m
	var m := src.duplicate() as StandardMaterial3D
	m.resource_name = src.resource_name + "_fade"
	m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	_fade_materials.append(m)
	return m

func set_occluder_fade(near: float, far: float) -> void:
	# Fully gone nearer than `near` to the camera, solid from `far`; keep `far` short of the samurai's distance.
	_fade = Vector2(near, far)
	for m in _fade_materials:
		m.distance_fade_min_distance = near
		m.distance_fade_max_distance = far

# --- queries for spawning and steering ---

func is_free(p: Vector3, margin: float) -> bool:
	var flat := Vector2(p.x, p.z)
	if flat.length() > play_radius_at(flat.angle()) - margin:
		return false
	for i in obstacles.size():
		var o := obstacles[i]
		if flat.distance_to(Vector2(o.x, o.z)) < obstacle_radii[i] + margin:
			return false
	return true

func clamp_to_play(p: Vector3, margin: float) -> Vector3:
	var flat := Vector2(p.x, p.z)
	var limit := play_radius_at(flat.angle()) - margin
	if flat.length() > limit:
		flat = flat.normalized() * limit
	return Vector3(flat.x, p.y, flat.y)

func steer(from: Vector3, dir: Vector3, radius: float, look_ahead: float = 2.6) -> Vector3:
	# Bend a flat move direction round the colliders ahead and away from the wall.
	if dir.length() < 0.01:
		return dir
	var d := Vector3(dir.x, 0.0, dir.z).normalized()
	var push := Vector3.ZERO
	for i in obstacles.size():
		var c := obstacles[i]
		var to_c := Vector3(c.x - from.x, 0.0, c.z - from.z)
		var reach := obstacle_radii[i] + radius + 0.25
		var t := to_c.dot(d)
		if t <= 0.0 or t > look_ahead + reach:
			continue
		var side := (d * t) - to_c
		var lateral := side.length()
		if lateral >= reach:
			continue
		if lateral < 0.01:
			side = Vector3(-d.z, 0.0, d.x)
		push += side.normalized() * (1.0 - lateral / reach) * 2.0
	var flat := Vector2(from.x, from.z)
	if flat.length() > play_radius_at(flat.angle()) - 1.6 and Vector2(d.x, d.z).dot(flat) > 0.0:
		push -= Vector3(flat.x, 0.0, flat.y).normalized() * 0.8
	return (d + push).normalized() * dir.length()

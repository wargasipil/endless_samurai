extends MeshInstance3D
## Crescent-shaped sword trail that sweeps in front of the player on each slash.
## Built procedurally so it needs no texture; faces +Z like the character models.

const SEGMENTS := 18

@export var inner_radius: float = 1.1
@export var outer_radius: float = 2.2
@export var arc_degrees: float = 150.0
@export var color: Color = Color(1.0, 0.92, 0.75)

var _mat: StandardMaterial3D
var _tween: Tween

func _ready() -> void:
	mesh = _build_mesh()
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.vertex_color_use_as_albedo = true
	_mat.albedo_color = Color(color, 0.0)
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false

func play(duration: float) -> void:
	if _tween:
		_tween.kill()
	visible = true
	_mat.albedo_color = Color(color, 1.0)
	rotation.y = deg_to_rad(35.0)
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "rotation:y", deg_to_rad(-35.0), duration * 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_mat, "albedo_color:a", 0.0, duration)
	_tween.chain().tween_callback(hide)

func _build_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := deg_to_rad(arc_degrees) * 0.5
	for i in SEGMENTS:
		var t0 := float(i) / SEGMENTS
		var t1 := float(i + 1) / SEGMENTS
		var a0 := lerpf(half, -half, t0)
		var a1 := lerpf(half, -half, t1)
		# Bright leading edge, fading tail; outer rim brighter than the inner one.
		var in0 := Color(1, 1, 1, t0 * 0.25)
		var in1 := Color(1, 1, 1, t1 * 0.25)
		var out0 := Color(1, 1, 1, t0)
		var out1 := Color(1, 1, 1, t1)
		var p_in0 := Vector3(sin(a0), 0, cos(a0)) * inner_radius
		var p_out0 := Vector3(sin(a0), 0, cos(a0)) * outer_radius
		var p_in1 := Vector3(sin(a1), 0, cos(a1)) * inner_radius
		var p_out1 := Vector3(sin(a1), 0, cos(a1)) * outer_radius
		_vert(st, p_in0, in0)
		_vert(st, p_out0, out0)
		_vert(st, p_out1, out1)
		_vert(st, p_in0, in0)
		_vert(st, p_out1, out1)
		_vert(st, p_in1, in1)
	return st.commit()

func _vert(st: SurfaceTool, p: Vector3, c: Color) -> void:
	st.set_color(c)
	st.add_vertex(p)

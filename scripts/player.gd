extends CharacterBody3D

const SPEED := 5.5
const JUMP_VELOCITY := 7.5
const GRAVITY := 20.0
const ATTACK_DURATION := 0.28
const HIT_KNOCKBACK := 6.0
const KNOCKBACK_TIME := 0.12

@export var max_health: int = 5

var health: int
var move_input: Vector2 = Vector2.ZERO
var jump_requested: bool = false
var attack_timer: float = 0.0
var knockback_timer: float = 0.0
var facing: Vector3 = Vector3(0.0, 0.0, -1.0)
var _hit_this_swing: Dictionary = {}

signal health_changed(current: int, maximum: int)
signal died
signal hit_landed(target: Node)

@onready var mesh_root: Node3D = $MeshRoot
@onready var sword_pivot: Node3D = $MeshRoot/SwordPivot
@onready var hit_area: Area3D = $MeshRoot/SwordPivot/HitArea
@onready var slash_vfx: MeshInstance3D = $MeshRoot/SwordPivot/Slash

func _ready() -> void:
	health = max_health
	hit_area.monitoring = true
	health_changed.emit(health, max_health)

func set_move_input(v: Vector2) -> void:
	move_input = v

func request_jump() -> void:
	jump_requested = true

func request_attack() -> void:
	if attack_timer <= 0.0:
		attack_timer = ATTACK_DURATION
		_hit_this_swing.clear()
		var tw := create_tween()
		sword_pivot.rotation.y = -PI * 0.55
		tw.tween_property(sword_pivot, "rotation:y", PI * 0.55, ATTACK_DURATION)
		_flash_slash()

func _flash_slash() -> void:
	if slash_vfx == null:
		return
	slash_vfx.visible = true
	var mat: StandardMaterial3D = slash_vfx.material_override
	if mat:
		mat.albedo_color = Color(1, 0.95, 0.8, 0.95)
		var tw := create_tween()
		tw.tween_property(mat, "albedo_color:a", 0.0, ATTACK_DURATION)
		tw.tween_callback(func() -> void:
			if is_instance_valid(slash_vfx):
				slash_vfx.visible = false
		)

func _apply_attack() -> void:
	for body in hit_area.get_overlapping_bodies():
		if not is_instance_valid(body):
			continue
		var id := body.get_instance_id()
		if _hit_this_swing.has(id):
			continue
		if body.has_method("take_damage"):
			_hit_this_swing[id] = true
			body.take_damage(1)
			if is_instance_valid(body) and body.has_method("apply_knockback"):
				var dir := (body.global_position - global_position)
				dir.y = 0.0
				if dir.length() < 0.01:
					dir = facing
				else:
					dir = dir.normalized()
				body.apply_knockback(dir * HIT_KNOCKBACK + Vector3(0.0, 3.0, 0.0))
			hit_landed.emit(body)

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	modulate_flash(Color(1, 0.5, 0.5))
	if health == 0:
		died.emit()
		set_physics_process(false)

func apply_knockback(impulse: Vector3) -> void:
	velocity = impulse
	knockback_timer = KNOCKBACK_TIME

func modulate_flash(c: Color) -> void:
	if mesh_root == null:
		return
	for child in mesh_root.get_children():
		if child is MeshInstance3D and child.material_override == null and (child as MeshInstance3D).mesh:
			continue
	# Flash via a shader-free trick: tween the mesh_root scale briefly.
	var tw := create_tween()
	mesh_root.scale = Vector3(1.1, 0.9, 1.1)
	tw.tween_property(mesh_root, "scale", Vector3.ONE, 0.2)

func _physics_process(delta: float) -> void:
	var input_dir := Vector3.ZERO
	if knockback_timer > 0.0:
		knockback_timer -= delta
	else:
		input_dir = Vector3(move_input.x, 0.0, move_input.y)
		var kx := 0.0
		var kz := 0.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			kx -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			kx += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			kz -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			kz += 1.0
		if absf(kx) + absf(kz) > 0.05:
			input_dir = Vector3(kx, 0.0, kz)
		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()
		velocity.x = input_dir.x * SPEED
		velocity.z = input_dir.z * SPEED

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = min(velocity.y, 0.0)

	var jump_now := jump_requested or Input.is_key_pressed(KEY_SPACE)
	if jump_now and is_on_floor():
		velocity.y = JUMP_VELOCITY
	jump_requested = false

	if Input.is_key_pressed(KEY_J):
		request_attack()

	# Face movement direction (ignore tiny jitter)
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() > 0.5:
		facing = flat.normalized()
		mesh_root.rotation.y = atan2(facing.x, facing.z)

	if attack_timer > 0.0:
		_apply_attack()
		attack_timer -= delta
		if attack_timer <= 0.0:
			sword_pivot.rotation.y = 0.0

	move_and_slide()

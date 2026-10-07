extends CharacterBody3D

const GRAVITY := 20.0
const CONTACT_KNOCKBACK := 5.0
const KNOCKBACK_TIME := 0.18

@export var max_health: int = 2
@export var contact_damage: int = 1
@export var move_speed: float = 2.5
@export var score_value: int = 10
@export var tint: Color = Color(1, 1, 1, 1)

var health: int
var target: Node3D
var hit_cooldown: float = 0.0
var knockback_timer: float = 0.0

signal defeated(enemy)

@onready var mesh_root: Node3D = $MeshRoot
@onready var body_mesh: MeshInstance3D = $MeshRoot/Body

func configure(profile: Dictionary) -> void:
	max_health = int(profile.get("hp", max_health))
	contact_damage = int(profile.get("damage", contact_damage))
	move_speed = float(profile.get("speed", move_speed))
	score_value = int(profile.get("score", score_value))
	tint = profile.get("tint", tint)

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	_apply_tint()

func _apply_tint() -> void:
	if body_mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.metallic = 0.0
	mat.roughness = 0.6
	body_mesh.material_override = mat

func set_target(t: Node3D) -> void:
	target = t

func take_damage(amount: int) -> void:
	health -= amount
	_flash_hit()
	if health <= 0:
		defeated.emit(self)
		queue_free()

func _flash_hit() -> void:
	if body_mesh == null or body_mesh.material_override == null:
		return
	var mat: StandardMaterial3D = body_mesh.material_override
	var original: Color = mat.albedo_color
	mat.albedo_color = Color(2.0, 0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color", original, 0.15)

func apply_knockback(impulse: Vector3) -> void:
	velocity = impulse
	knockback_timer = KNOCKBACK_TIME

func _physics_process(delta: float) -> void:
	if knockback_timer > 0.0:
		knockback_timer -= delta
	elif target and is_instance_valid(target):
		var to_target: Vector3 = target.global_position - global_position
		to_target.y = 0.0
		var dist: float = to_target.length()
		if dist > 0.01:
			var dir: Vector3 = to_target / dist
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			mesh_root.rotation.y = atan2(dir.x, dir.z)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = min(velocity.y, 0.0)

	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	move_and_slide()

	if target and is_instance_valid(target) and hit_cooldown <= 0.0:
		var flat_dist := Vector2(target.global_position.x - global_position.x, target.global_position.z - global_position.z).length()
		if flat_dist < 1.1 and target.has_method("take_damage"):
			target.take_damage(contact_damage)
			if is_instance_valid(target) and target.has_method("apply_knockback"):
				var push: Vector3 = (target.global_position - global_position)
				push.y = 0.0
				if push.length() > 0.01:
					push = push.normalized()
				else:
					push = Vector3(0, 0, -1)
				target.apply_knockback(push * CONTACT_KNOCKBACK + Vector3(0, 2.5, 0))
			hit_cooldown = 0.8

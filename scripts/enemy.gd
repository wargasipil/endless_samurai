extends CharacterBody3D

const GRAVITY := 20.0
const CONTACT_KNOCKBACK := 5.0
const KNOCKBACK_TIME := 0.18
# Models from the Blender project's library (run.ps1 game-characters). Their move actions are in place, so they play
# at the enemy's speed over the action's own speed (m/s at scale 1; person_meta.RUN_V / WALK_V, wraith_meta.GLIDE_V).
const MODELS := {
	"skeleton": preload("res://assets/characters/skeleton.glb"),
	"wraith": preload("res://assets/characters/wraith.glb"),
}
const MOVES := {
	"skeleton": [["Skeleton_Run", 2.088], ["Skeleton_Walk", 0.696]],
	"wraith": [["Wraith_Glide", 1.2]],
}
# The attack's strike: [action, start (s), rate]: the skeleton's cut (frame 9 on), the wraith's lunge (frame 8 on)
const ATTACKS := {
	"skeleton": ["Skeleton_Attack", 8.0 / 24.0, 1.8],
	"wraith": ["Wraith_Attack", 7.0 / 24.0, 1.6],
}

@export var max_health: int = 2
@export var contact_damage: int = 1
@export var move_speed: float = 2.5
@export var score_value: int = 10
@export var tint: Color = Color(1, 1, 1, 1)
@export var model_kind: String = "skeleton"
@export var model_scale: float = 1.15

var health: int
var target: Node3D
var hit_cooldown: float = 0.0
var knockback_timer: float = 0.0
var anim: AnimationPlayer
var _anim_state := ""
var _attack_anim_timer: float = 0.0
var _flash_mat: StandardMaterial3D
var _arena: Arena

signal defeated(enemy)

@onready var mesh_root: Node3D = $MeshRoot

func configure(profile: Dictionary) -> void:
	max_health = int(profile.get("hp", max_health))
	contact_damage = int(profile.get("damage", contact_damage))
	move_speed = float(profile.get("speed", move_speed))
	score_value = int(profile.get("score", score_value))
	tint = profile.get("tint", tint)
	model_kind = profile.get("model", model_kind)
	model_scale = float(profile.get("scale", model_scale))

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	_arena = get_tree().get_first_node_in_group("arena") as Arena
	_add_model()

func _add_model() -> void:
	var m: Node3D = MODELS[model_kind].instantiate()
	m.scale = Vector3.ONE * model_scale
	mesh_root.add_child(m)
	anim = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for mv in MOVES[model_kind]:
		anim.get_animation(mv[0]).loop_mode = Animation.LOOP_LINEAR
	# Hit flash: a red overlay on every part of the model, faded out in _flash_hit.
	_flash_mat = StandardMaterial3D.new()
	_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_mat.albedo_color = Color(1.0, 0.25, 0.2, 0.0)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = _flash_mat
	_update_anim(move_speed)

func _update_anim(speed: float) -> void:
	if anim == null or _attack_anim_timer > 0.0:
		return
	# The run below 3/4 of its own speed looks like slow motion: walk instead (the big skeleton).
	var moves: Array = MOVES[model_kind]
	var pick: Array = moves[0]
	var base: float = pick[1] * model_scale
	if moves.size() > 1 and speed < base * 0.75:
		pick = moves[1]
		base = pick[1] * model_scale
	var rate := clampf(speed / base, 0.5, 1.8 if model_kind == "wraith" else 3.0)
	if _anim_state != pick[0]:
		anim.play(pick[0], 0.15)
		_anim_state = pick[0]
	anim.speed_scale = rate

func _play_attack() -> void:
	if anim == null:
		return
	var a: Array = ATTACKS[model_kind]
	anim.play(a[0], 0.05)
	anim.seek(a[1], true)
	anim.speed_scale = a[2]
	_anim_state = a[0]
	_attack_anim_timer = 0.45

func set_target(t: Node3D) -> void:
	target = t

func take_damage(amount: int) -> void:
	health -= amount
	_flash_hit()
	if health <= 0:
		defeated.emit(self)
		queue_free()

func _flash_hit() -> void:
	if _flash_mat == null:
		return
	_flash_mat.albedo_color.a = 0.65
	var tw := create_tween()
	tw.tween_property(_flash_mat, "albedo_color:a", 0.0, 0.18)

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
			if _arena:
				dir = _arena.steer(global_position, dir, 0.45)
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
	_attack_anim_timer = maxf(0.0, _attack_anim_timer - delta)
	move_and_slide()
	_update_anim(Vector2(velocity.x, velocity.z).length())

	if target and is_instance_valid(target) and hit_cooldown <= 0.0:
		var flat_dist := Vector2(target.global_position.x - global_position.x, target.global_position.z - global_position.z).length()
		if flat_dist < 1.1 and target.has_method("take_damage"):
			_play_attack()
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

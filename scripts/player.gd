extends CharacterBody3D

const SPEED := 6.0
const ACCEL := 45.0
const JUMP_VELOCITY := 8.0
const GRAVITY := 22.0
const ATTACK_DURATION := 0.4
const ATTACK_HIT_DELAY := 0.1
const ATTACK_RANGE := 2.4
const ATTACK_ARC_COS := 0.26  # ~75 degrees either side of facing
const AUTO_AIM_RANGE := 4.0
const HIT_KNOCKBACK := 7.0

@export var max_health: int = 5
@export var arena_radius: float = 18.0

var health: int
var move_input: Vector2 = Vector2.ZERO
var jump_requested: bool = false
var attack_timer: float = 0.0
var attack_pending: bool = false
var knockback_timer: float = 0.0
var facing: Vector3 = Vector3.BACK
var dead: bool = false

signal health_changed(current: int, maximum: int)
signal died
signal hit_landed(target: Node)

@onready var pivot: Node3D = $Pivot
@onready var model: CharacterModel = $Pivot/Model
@onready var slash_vfx: MeshInstance3D = $Pivot/Slash

func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)

func set_move_input(v: Vector2) -> void:
	move_input = v

func request_jump() -> void:
	jump_requested = true

func request_attack() -> void:
	if dead or attack_timer > 0.0:
		return
	attack_timer = ATTACK_DURATION
	attack_pending = true
	_auto_aim()
	model.play_once("Weapon", model.clip_length("Weapon") / ATTACK_DURATION)
	slash_vfx.play(ATTACK_DURATION)

## Turns toward the nearest enemy in reach so slashing on a phone feels fair.
func _auto_aim() -> void:
	var best: Node3D = null
	var best_dist := AUTO_AIM_RANGE
	for e in get_tree().get_nodes_in_group("enemies"):
		var d: float = _flat(e.global_position - global_position).length()
		if d < best_dist:
			best_dist = d
			best = e
	if best and best_dist > 0.01:
		facing = _flat(best.global_position - global_position).normalized()
	pivot.rotation.y = atan2(facing.x, facing.z)

func _apply_attack() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		var to := _flat(e.global_position - global_position)
		var dist := to.length()
		if dist > ATTACK_RANGE:
			continue
		var dir := to / dist if dist > 0.01 else facing
		# Anything hugging the player is hit regardless of angle.
		if dist > 0.8 and facing.dot(dir) < ATTACK_ARC_COS:
			continue
		e.take_damage(1)
		e.apply_knockback(dir * HIT_KNOCKBACK + Vector3.UP * 4.0)
		hit_landed.emit(e)

func take_damage(amount: int) -> void:
	if dead:
		return
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	model.flash(Color(1, 0.15, 0.15, 0.75), 0.25)
	if health == 0:
		dead = true
		attack_timer = 0.0
		model.play_once("Death")
		died.emit()
	elif attack_timer <= 0.0:
		model.play_once("HitReact", 1.5)

func apply_knockback(impulse: Vector3) -> void:
	velocity = impulse
	knockback_timer = 0.15

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO if dead else _read_move_input()
	var dir := Vector3(input.x, 0.0, input.y)

	if knockback_timer > 0.0:
		knockback_timer -= delta
	else:
		velocity.x = move_toward(velocity.x, dir.x * SPEED, ACCEL * delta)
		velocity.z = move_toward(velocity.z, dir.z * SPEED, ACCEL * delta)

	if dir.length() > 0.1 and attack_timer <= 0.0:
		facing = dir.normalized()
	pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(facing.x, facing.z), 1.0 - exp(-14.0 * delta))

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var jump_now := jump_requested or Input.is_key_pressed(KEY_SPACE)
	jump_requested = false
	if jump_now and is_on_floor() and not dead:
		velocity.y = JUMP_VELOCITY
		model.play_once("Jump", 1.2)

	if not dead and Input.is_key_pressed(KEY_J):
		request_attack()

	if attack_timer > 0.0:
		attack_timer -= delta
		if attack_pending and attack_timer <= ATTACK_DURATION - ATTACK_HIT_DELAY:
			attack_pending = false
			_apply_attack()

	move_and_slide()
	_clamp_to_arena()
	_update_animation()

func _read_move_input() -> Vector2:
	var keys := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
			- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
			- float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	)
	var v := keys if keys != Vector2.ZERO else move_input
	return v.limit_length(1.0)

func _clamp_to_arena() -> void:
	var flat := _flat(global_position)
	if flat.length() > arena_radius:
		flat = flat.normalized() * arena_radius
		global_position = Vector3(flat.x, global_position.y, flat.z)

func _update_animation() -> void:
	if dead:
		return
	var speed := _flat(velocity).length()
	if not is_on_floor():
		model.play("Jump_Idle")
	elif speed > 0.5:
		model.play("Run", clampf(speed / SPEED, 0.6, 1.2))
	else:
		model.play("Idle")

func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)

extends CharacterBody3D

const GRAVITY := 22.0
const ATTACK_RANGE := 1.7
const ATTACK_WINDUP := 0.4
const ATTACK_COOLDOWN := 1.2
const CONTACT_KNOCKBACK := 6.0
const TURN_RATE := 10.0

@export var max_health: int = 2
@export var contact_damage: int = 1
@export var move_speed: float = 2.6
@export var score_value: int = 10
@export var model_scene: PackedScene
@export var model_scale: float = 0.9
@export var body_radius: float = 0.45
@export var body_height: float = 1.8

var health: int
var target: Node3D
var attack_cooldown: float = 0.0
var windup: float = -1.0
var knockback_timer: float = 0.0
var dying: bool = false

signal defeated(enemy)

@onready var pivot: Node3D = $Pivot
@onready var model: CharacterModel = $Pivot/Model
@onready var shape_node: CollisionShape3D = $CollisionShape3D

func configure(profile: Dictionary) -> void:
	max_health = int(profile.get("hp", max_health))
	contact_damage = int(profile.get("damage", contact_damage))
	move_speed = float(profile.get("speed", move_speed))
	score_value = int(profile.get("score", score_value))
	model_scene = profile.get("model", model_scene)
	model_scale = float(profile.get("scale", model_scale))
	body_radius = float(profile.get("radius", body_radius))
	body_height = float(profile.get("height", body_height))

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	model.scale = Vector3.ONE * model_scale
	model.set_model(model_scene)
	var capsule := CapsuleShape3D.new()
	capsule.radius = body_radius
	capsule.height = maxf(body_radius * 2.0, body_height)
	shape_node.shape = capsule
	shape_node.position.y = capsule.height * 0.5

func set_target(t: Node3D) -> void:
	target = t
	if t == null:
		windup = -1.0

func take_damage(amount: int) -> void:
	if dying:
		return
	health -= amount
	model.flash(Color(1, 1, 1, 0.85), 0.15)
	if health <= 0:
		_die()
		return
	windup = -1.0  # a hit interrupts the swing
	model.play_once("HitReact", 1.4)

func apply_knockback(impulse: Vector3) -> void:
	velocity = impulse
	knockback_timer = 0.2

func _die() -> void:
	dying = true
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 1
	defeated.emit(self)
	model.play_once("Death")
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(pivot, "position:y", -2.0, 0.8)
	tw.tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)

	if knockback_timer > 0.0 or dying:
		knockback_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 25.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 25.0 * delta)
	elif windup >= 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		windup -= delta
		if windup < 0.0:
			_strike()
	elif target:
		var to := target.global_position - global_position
		to.y = 0.0
		var dist := to.length()
		_turn_toward(to, delta)
		if dist <= ATTACK_RANGE + body_radius and attack_cooldown <= 0.0:
			windup = ATTACK_WINDUP
			attack_cooldown = ATTACK_COOLDOWN
			velocity.x = 0.0
			velocity.z = 0.0
			model.play_once("Weapon", model.clip_length("Weapon") / (ATTACK_WINDUP + 0.35))
		elif dist > ATTACK_RANGE * 0.7 + body_radius:
			var dir := to / dist
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	move_and_slide()
	if not dying:
		_update_animation()

func _strike() -> void:
	# Keep a local reference: a killing blow makes main clear every enemy's target.
	var victim := target
	if victim == null or not victim.has_method("take_damage"):
		return
	var to := victim.global_position - global_position
	to.y = 0.0
	if to.length() > ATTACK_RANGE + body_radius + 0.5:
		return  # the player stepped out of reach
	victim.take_damage(contact_damage)
	if victim.has_method("apply_knockback"):
		victim.apply_knockback(to.normalized() * CONTACT_KNOCKBACK + Vector3.UP * 3.0)

func _turn_toward(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-TURN_RATE * delta))

func _update_animation() -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed > 3.5:
		model.play("Run", speed / 4.5)
	elif speed > 0.2:
		model.play("Walk", speed / 1.8)
	else:
		model.play("Idle")

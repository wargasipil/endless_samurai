extends CharacterBody2D

const SPEED := 260.0
const JUMP_VELOCITY := -720.0
const GRAVITY := 1800.0
const ATTACK_DURATION := 0.25
const HIT_KNOCKBACK := 260.0

@export var max_health: int = 5

var health: int
var move_input: Vector2 = Vector2.ZERO
var jump_requested: bool = false
var attack_timer: float = 0.0
var knockback_timer: float = 0.0
var facing: int = 1

signal health_changed(current: int, maximum: int)
signal died
signal hit_landed(target: Node)

@onready var sprite: Sprite2D = $Sprite
@onready var sword: Node2D = $Sword
@onready var hit_area: Area2D = $Sword/HitArea
@onready var slash_vfx: Line2D = $Sword/Slash

func _ready() -> void:
	health = max_health
	hit_area.monitoring = false
	slash_vfx.modulate.a = 0.0
	health_changed.emit(health, max_health)

func set_move_input(v: Vector2) -> void:
	move_input = v

func request_jump() -> void:
	jump_requested = true

func request_attack() -> void:
	if attack_timer <= 0.0:
		attack_timer = ATTACK_DURATION
		hit_area.monitoring = true
		sword.rotation_degrees = -30.0
		_play_slash_vfx()
		_apply_attack()

func _play_slash_vfx() -> void:
	slash_vfx.modulate = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_property(slash_vfx, "modulate:a", 0.0, ATTACK_DURATION)

func _apply_attack() -> void:
	for body in hit_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(1)
			if body.has_method("apply_knockback"):
				body.apply_knockback(Vector2(facing * 340.0, -180.0))
			hit_landed.emit(body)

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	modulate = Color(1, 0.5, 0.5)
	create_tween().tween_property(self, "modulate", Color(1, 1, 1), 0.2)
	if health == 0:
		died.emit()
		set_physics_process(false)

func apply_knockback(impulse: Vector2) -> void:
	velocity = impulse
	knockback_timer = 0.12

func _physics_process(delta: float) -> void:
	var x_axis := 0.0
	if knockback_timer > 0.0:
		knockback_timer -= delta
	else:
		x_axis = move_input.x
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			x_axis = -1.0
		elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			x_axis = 1.0
		velocity.x = x_axis * SPEED

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = min(velocity.y, 0.0)

	var jump_now := jump_requested or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W)
	if jump_now and is_on_floor():
		velocity.y = JUMP_VELOCITY
	jump_requested = false

	if Input.is_key_pressed(KEY_J):
		request_attack()

	if absf(x_axis) > 0.05:
		facing = 1 if x_axis > 0.0 else -1
		sprite.flip_h = facing < 0
		sword.scale.x = facing

	if attack_timer > 0.0:
		attack_timer -= delta
		if attack_timer <= 0.0:
			hit_area.monitoring = false
			sword.rotation_degrees = 0.0

	move_and_slide()

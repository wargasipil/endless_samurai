extends CharacterBody2D

const GRAVITY := 1800.0
const CONTACT_KNOCKBACK := 200.0

@export var max_health: int = 2
@export var contact_damage: int = 1
@export var move_speed: float = 90.0
@export var score_value: int = 10
@export var tint: Color = Color(1, 1, 1, 1)

var health: int
var target: Node2D
var hit_cooldown: float = 0.0
var knockback_timer: float = 0.0

signal defeated(enemy)

@onready var sprite: Sprite2D = $Sprite

func configure(profile: Dictionary) -> void:
	max_health = int(profile.get("hp", max_health))
	contact_damage = int(profile.get("damage", contact_damage))
	move_speed = float(profile.get("speed", move_speed))
	score_value = int(profile.get("score", score_value))
	tint = profile.get("tint", tint)

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	if sprite:
		sprite.modulate = tint

func set_target(t: Node2D) -> void:
	target = t

func take_damage(amount: int) -> void:
	health -= amount
	modulate = Color(1.8, 0.6, 0.6)
	create_tween().tween_property(self, "modulate", Color(1, 1, 1), 0.15)
	if health <= 0:
		defeated.emit(self)
		queue_free()

func apply_knockback(impulse: Vector2) -> void:
	velocity = impulse
	knockback_timer = 0.18

func _physics_process(delta: float) -> void:
	if knockback_timer > 0.0:
		knockback_timer -= delta
	elif target:
		var dir := signf(target.global_position.x - global_position.x)
		velocity.x = dir * move_speed
		sprite.flip_h = dir < 0.0
	else:
		velocity.x = 0.0

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = min(velocity.y, 0.0)

	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	move_and_slide()

	if target and hit_cooldown <= 0.0 and global_position.distance_to(target.global_position) < 48.0:
		if target.has_method("take_damage"):
			target.take_damage(contact_damage)
			if target.has_method("apply_knockback"):
				var push := signf(target.global_position.x - global_position.x)
				target.apply_knockback(Vector2(push * CONTACT_KNOCKBACK, -140.0))
			hit_cooldown = 0.8

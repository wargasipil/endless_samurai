extends Node

# Autopilot used for recording promo footage via `godot --write-movie`.
# Enabled when `--demo` is present in the command-line user args;
# main.gd attaches an instance of this node to the World.

const ATTACK_RANGE := 110.0
const APPROACH_DEADZONE := 24.0
const BUNCH_JUMP_DISTANCE := 220.0

var _player: CharacterBody2D
var _jump_cooldown: float = 0.0

func setup(player: CharacterBody2D) -> void:
	_player = player

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	_jump_cooldown = maxf(0.0, _jump_cooldown - delta)

	var enemy := _nearest_enemy()
	if enemy == null:
		_player.set_move_input(Vector2.ZERO)
		return

	var dx: float = enemy.global_position.x - _player.global_position.x
	var ax: float = absf(dx)

	var dir := 0.0
	if ax > APPROACH_DEADZONE:
		dir = signf(dx)
	_player.set_move_input(Vector2(dir, 0.0))

	if ax < ATTACK_RANGE:
		_player.request_attack()

	if _jump_cooldown <= 0.0 and _player.is_on_floor():
		var close := 0
		for n in get_tree().get_nodes_in_group("enemies"):
			if n is Node2D and absf((n as Node2D).global_position.x - _player.global_position.x) < BUNCH_JUMP_DISTANCE:
				close += 1
		if close >= 2 or randf() < 0.004:
			_player.request_jump()
			_jump_cooldown = 1.1

func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Node2D:
			var d: float = (n as Node2D).global_position.distance_to(_player.global_position)
			if d < best_d:
				best = n as Node2D
				best_d = d
	return best

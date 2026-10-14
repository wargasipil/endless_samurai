extends Node

# Autopilot used for recording promo footage via `godot --write-movie`.
# Enabled when `--demo` is present in the command-line user args;
# main.gd attaches an instance of this node to the World.

const ATTACK_RANGE := 2.4
const APPROACH_DEADZONE := 0.4
const BUNCH_JUMP_RADIUS := 4.0
# Stay round the courtyard (the arena's centre): chase only enemies near it, or right beside him, and walk back
# otherwise. On the wide map he ran off after far enemies, out along the rim where the camera saw no fight and the
# dark wraiths were lost in the trees' shadows; the enemies come to him anyway.
const HOME := Vector3.ZERO
const LEASH := 8.5
const CLOSE := 3.0

var _player: CharacterBody3D
var _jump_cooldown: float = 0.0
var _arena: Arena

func setup(player: CharacterBody3D) -> void:
	_player = player

func _ready() -> void:
	_arena = get_tree().get_first_node_in_group("arena") as Arena

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	_jump_cooldown = maxf(0.0, _jump_cooldown - delta)

	var enemy := _nearest_enemy()
	if enemy == null:
		var home := HOME - _player.global_position
		home.y = 0.0
		if home.length() > 1.5:
			var hd := home.normalized()
			if _arena:
				hd = _arena.steer(_player.global_position, hd, 0.45)
			_player.set_move_input(Vector2(hd.x, hd.z))
		else:
			_player.set_move_input(Vector2.ZERO)
		return

	var to_target: Vector3 = enemy.global_position - _player.global_position
	to_target.y = 0.0
	var dist: float = to_target.length()

	var move := Vector2.ZERO
	if dist > APPROACH_DEADZONE:
		var dir: Vector3 = to_target.normalized()
		if _arena:
			dir = _arena.steer(_player.global_position, dir, 0.45)
		move = Vector2(dir.x, dir.z)
	_player.set_move_input(move)

	if dist < ATTACK_RANGE:
		_player.request_attack()

	if _jump_cooldown <= 0.0 and _player.is_on_floor():
		var close := 0
		for n in get_tree().get_nodes_in_group("enemies"):
			if n is Node3D:
				var d: float = (n as Node3D).global_position.distance_to(_player.global_position)
				if d < BUNCH_JUMP_RADIUS:
					close += 1
		if close >= 2 or randf() < 0.004:
			_player.request_jump()
			_jump_cooldown = 1.1

func _nearest_enemy() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Node3D:
			var p := (n as Node3D).global_position
			var d: float = p.distance_to(_player.global_position)
			if Vector2(p.x - HOME.x, p.z - HOME.z).length() > LEASH and d > CLOSE:
				continue
			if d < best_d:
				best = n as Node3D
				best_d = d
	return best

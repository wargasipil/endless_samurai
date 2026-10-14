extends Node3D

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const SAVE_PATH := "user://save.cfg"
const SPAWN_RADIUS := 14.0
# Portrait screens (phones, the TikTok capture) see a narrow strip with the landscape camera:
# frame by width there, a little higher, so the arena around the samurai stays in view.
const PORTRAIT_FOV := 50.0
const PORTRAIT_OFFSET := Vector3(0.0, 6.6, 6.0)

const ENEMY_VARIANTS := {
	"grunt":  {"hp": 2, "damage": 1, "speed": 2.5, "score": 10, "tint": Color(0.85, 0.2, 0.2), "model": "skeleton", "scale": 1.15},
	"runner": {"hp": 1, "damage": 1, "speed": 4.2, "score": 15, "tint": Color(1.0, 0.6, 0.2), "model": "wraith", "scale": 1.0},
	"brute":  {"hp": 5, "damage": 2, "speed": 1.8, "score": 30, "tint": Color(0.6, 0.3, 0.9), "model": "skeleton", "scale": 1.5},
}

@onready var player: CharacterBody3D = $World/Player
@onready var camera: Camera3D = $World/CameraRig/Camera3D
@onready var camera_rig: Node3D = $World/CameraRig
@onready var arena: Arena = $World/Arena
@onready var hud_label: Label = $UI/HUD/HudLabel
@onready var health_bar: HealthBar = $UI/HUD/HealthBar
@onready var hp_text: Label = $UI/HUD/HpText
@onready var wave_banner: Label = $UI/HUD/WaveBanner
@onready var game_over_panel: Control = $UI/GameOver
@onready var game_over_label: Label = $UI/GameOver/Panel/Label
@onready var controls: CanvasLayer = $Controls
@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer = $WaveTimer

var wave: int = 0
var kills: int = 0
var score: int = 0
var best_score: int = 0
var alive: bool = true
var _landscape_cam: Array = []

func _ready() -> void:
	randomize()
	best_score = _load_best()
	_landscape_cam = [camera.transform, camera.fov, camera.keep_aspect]
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()

	controls.move_vector.connect(_on_move)
	controls.jump_pressed.connect(func() -> void: player.request_jump())
	controls.attack_pressed.connect(func() -> void: player.request_attack())

	player.health_changed.connect(_on_health_changed)
	player.hit_landed.connect(_on_hit_landed)
	player.died.connect(_on_player_died)

	spawn_timer.timeout.connect(_spawn_enemy)
	wave_timer.timeout.connect(_advance_wave)

	game_over_panel.visible = false
	_advance_wave()
	_refresh_hud()
	_refresh_hp_bar(player.health, player.max_health)

	if "--demo" in OS.get_cmdline_user_args():
		_enter_demo_mode()

func _enter_demo_mode() -> void:
	controls.visible = false
	player.max_health = 20
	player.health = 20
	player.health_changed.emit(player.health, player.max_health)
	var demo := preload("res://scripts/demo_controller.gd").new()
	demo.name = "DemoController"
	demo.setup(player)
	$World.add_child(demo)

func _fit_camera() -> void:
	var size := get_viewport().get_visible_rect().size
	if size.y > size.x:
		camera.keep_aspect = Camera3D.KEEP_WIDTH
		camera.fov = PORTRAIT_FOV
		camera.transform = Transform3D(Basis.looking_at(-PORTRAIT_OFFSET + Vector3(0.0, 0.5, 0.0)), PORTRAIT_OFFSET)
	else:
		camera.keep_aspect = _landscape_cam[2]
		camera.fov = _landscape_cam[1]
		camera.transform = _landscape_cam[0]
	if camera.has_method("set_base_offset"):
		camera.set_base_offset(camera.position)
	var dist := camera.position.length()
	arena.set_occluder_fade(dist - 4.5, dist - 1.3)

func _process(_delta: float) -> void:
	if camera_rig and player:
		camera_rig.global_position = camera_rig.global_position.lerp(
			Vector3(player.global_position.x, 0.0, player.global_position.z),
			0.08
		)

func _advance_wave() -> void:
	wave += 1
	var interval: float = maxf(0.6, 2.6 - wave * 0.15)
	spawn_timer.wait_time = interval
	spawn_timer.start()
	wave_timer.wait_time = 20.0
	wave_timer.start()
	_show_banner("Wave %d" % wave)

func _show_banner(text: String) -> void:
	wave_banner.text = text
	wave_banner.modulate = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(wave_banner, "modulate:a", 0.0, 0.8)

func _on_move(v: Vector2) -> void:
	player.set_move_input(v)

func _spawn_enemy() -> void:
	if not alive:
		return
	var profile := _roll_variant()
	profile = _scale_for_wave(profile)
	var e := ENEMY_SCENE.instantiate()
	e.configure(profile)
	e.set_target(player)
	e.defeated.connect(_on_enemy_defeated)
	$World.add_child(e)
	e.global_position = _spawn_point()

func _spawn_point() -> Vector3:
	# On the island, clear of stones, trees and the shrine, not on top of the samurai.
	var best := Vector3.ZERO
	for i in 24:
		var angle := randf() * TAU
		var r := SPAWN_RADIUS * randf_range(0.7, 1.0)
		var p := arena.clamp_to_play(player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * r, 1.0)
		if arena.is_free(p, 0.8) and p.distance_to(player.global_position) > 6.0:
			return p + Vector3(0.0, 0.5, 0.0)
		best = p
	return best + Vector3(0.0, 0.5, 0.0)

func _roll_variant() -> Dictionary:
	var roll := randf()
	var key := "grunt"
	if wave >= 3 and roll < 0.25:
		key = "brute"
	elif wave >= 2 and roll < 0.55:
		key = "runner"
	return ENEMY_VARIANTS[key].duplicate(true)

func _scale_for_wave(profile: Dictionary) -> Dictionary:
	var tier: int = max(0, wave - 1)
	profile["hp"] = int(profile["hp"]) + int(tier / 2)
	profile["speed"] = float(profile["speed"]) + tier * 0.2
	return profile

func _on_enemy_defeated(e) -> void:
	kills += 1
	score += int(e.score_value)
	_refresh_hud()

func _on_health_changed(current: int, maximum: int) -> void:
	_refresh_hp_bar(current, maximum)
	if current < player.max_health:
		_shake(0.6, 0.25)

func _on_hit_landed(_target: Node) -> void:
	_shake(0.35, 0.15)

func _shake(strength: float, duration: float) -> void:
	if camera and camera.has_method("shake"):
		camera.shake(strength, duration)

func _refresh_hud() -> void:
	hud_label.text = "Wave %d   Score %d   Best %d" % [wave, score, best_score]

func _refresh_hp_bar(current: int, maximum: int) -> void:
	hp_text.text = "%d / %d" % [current, maximum]
	if is_equal_approx(health_bar.max_health, maximum):
		health_bar.set_health(current)
	else:
		# Max HP changed (first frame, or --demo bumping it): snap, don't slide
		health_bar.reset_health(current, maximum)

func _on_player_died() -> void:
	alive = false
	spawn_timer.stop()
	wave_timer.stop()
	for n in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(n) and n.has_method("set_target"):
			n.set_target(null)
	if score > best_score:
		best_score = score
		_save_best(best_score)
	game_over_label.text = "DEFEATED\nWave %d   Score %d\nBest %d\n\nTap to restart" % [wave, score, best_score]
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	create_tween().tween_property(game_over_panel, "modulate:a", 1.0, 0.6)

func _unhandled_input(event: InputEvent) -> void:
	if alive:
		return
	var fired := false
	if event is InputEventScreenTouch and event.pressed:
		fired = true
	elif event is InputEventMouseButton and event.pressed:
		fired = true
	elif event is InputEventKey and event.pressed:
		fired = true
	if fired:
		get_tree().reload_current_scene()

func _load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		return int(cfg.get_value("stats", "best_score", 0))
	return 0

func _save_best(value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "best_score", value)
	cfg.save(SAVE_PATH)

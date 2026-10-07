extends Node2D

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const SAVE_PATH := "user://save.cfg"
const ARENA_LIMIT := 1900.0

const ENEMY_VARIANTS := {
	"grunt":  {"hp": 2, "damage": 1, "speed": 90.0,  "score": 10, "tint": Color(1.0, 1.0, 1.0)},
	"runner": {"hp": 1, "damage": 1, "speed": 170.0, "score": 15, "tint": Color(1.0, 0.7, 0.4)},
	"brute":  {"hp": 5, "damage": 2, "speed": 60.0,  "score": 30, "tint": Color(0.6, 0.5, 1.0)},
}

@onready var player: CharacterBody2D = $World/Player
@onready var hud_label: Label = $UI/HUD/HudLabel
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

func _ready() -> void:
	randomize()
	best_score = _load_best()

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

	if "--demo" in OS.get_cmdline_user_args():
		_enter_demo_mode()

func _enter_demo_mode() -> void:
	controls.visible = false
	var demo := preload("res://scripts/demo_controller.gd").new()
	demo.name = "DemoController"
	demo.setup(player)
	$World.add_child(demo)

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
	var side := 1.0 if randf() < 0.5 else -1.0
	var px: float = clampf(player.global_position.x + side * 700.0, -ARENA_LIMIT, ARENA_LIMIT)
	e.global_position = Vector2(px, player.global_position.y - 240.0)
	e.set_target(player)
	e.defeated.connect(_on_enemy_defeated)
	$World.add_child(e)

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
	profile["speed"] = float(profile["speed"]) + tier * 6.0
	return profile

func _on_enemy_defeated(e) -> void:
	kills += 1
	score += int(e.score_value)
	_refresh_hud()

func _on_health_changed(current: int, _maximum: int) -> void:
	_refresh_hud()
	if current < player.max_health:
		_shake(10.0, 0.25)

func _on_hit_landed(_target: Node) -> void:
	_shake(6.0, 0.15)

func _shake(strength: float, duration: float) -> void:
	var cam := player.get_node_or_null("Camera")
	if cam and cam.has_method("shake"):
		cam.shake(strength, duration)

func _refresh_hud() -> void:
	hud_label.text = "Wave %d   HP %d/%d   Score %d   Best %d" % [
		wave, player.health, player.max_health, score, best_score
	]

func _on_player_died() -> void:
	alive = false
	spawn_timer.stop()
	wave_timer.stop()
	for n in get_tree().get_nodes_in_group("enemies"):
		if n.has_method("set_target"):
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

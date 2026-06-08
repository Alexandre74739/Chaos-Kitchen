extends Node3D

const CLIENT_SCENE        = preload("res://entities/personnages/client.tscn")
const SCORE_UI_SCRIPT     = "res://scripts/score_ui.gd"
const PAUSE_MENU_SCRIPT   = "res://scripts/pause_menu.gd"
const GAME_OVER_SCRIPT    = "res://scripts/game_over.gd"

const SPAWN_MIN           = 15.0
const SPAWN_MAX           = 30.0
const MIN_CLIENTS         = 2
const MAX_CLIENTS         = 8
const DELAI_REMPLACEMENT  = 4.0
const SEUIL_DEFAITE       = -500

var chaises          : Array = []
var timer_spawn      : Timer
var nb_clients       : int   = 0
var score            : int   = 0
var score_ui         : Node  = null
var pause_menu       : Node  = null
var game_over_screen : Node  = null

func _ready() -> void:
	AudioManager.jouer_ambiance("ambiance")
	_collecter_chaises()
	_lancer_timer_spawn()
	_creer_score_ui()
	_creer_pause_menu()
	_creer_game_over()
	for i in range(MIN_CLIENTS):
		_spawner_client()

# ── Score UI ──────────────────────────────────────────────────
func _creer_score_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.set_script(load(SCORE_UI_SCRIPT))
	add_child(canvas)
	score_ui = canvas

# ── Menu Pause ────────────────────────────────────────────────
func _creer_pause_menu() -> void:
	var canvas = CanvasLayer.new()
	canvas.set_script(load(PAUSE_MENU_SCRIPT))
	add_child(canvas)
	pause_menu = canvas

# ── Écran Game Over ───────────────────────────────────────────
func _creer_game_over() -> void:
	var canvas = CanvasLayer.new()
	canvas.set_script(load(GAME_OVER_SCRIPT))
	add_child(canvas)
	game_over_screen = canvas

# ── Collecte toutes les positions de chaises dans la salle ───
func _collecter_chaises() -> void:
	var salle = $SalleRestaurant
	for table in salle.get_children():
		var centre_table = table.global_position
		for enfant in table.get_children():
			if enfant.name.begins_with("chaise"):
				chaises.append({
					"position": enfant.global_position + Vector3(0, 0.6, 0),
					"look_at":  centre_table,
					"occupee":  false
				})

# ── Cycle de spawn ────────────────────────────────────────────
func _lancer_timer_spawn() -> void:
	timer_spawn          = Timer.new()
	timer_spawn.one_shot = true
	add_child(timer_spawn)
	timer_spawn.timeout.connect(_spawner_client)
	_programmer_prochain_spawn()

func _programmer_prochain_spawn() -> void:
	timer_spawn.wait_time = randf_range(SPAWN_MIN, SPAWN_MAX)
	timer_spawn.start()

# ── Installe un client sur une chaise libre ───────────────────
func _spawner_client() -> void:
	if nb_clients >= MAX_CLIENTS:
		_programmer_prochain_spawn()
		return

	var libres : Array = []
	for i in range(chaises.size()):
		if not chaises[i]["occupee"]:
			libres.append(i)

	if libres.is_empty():
		_programmer_prochain_spawn()
		return

	var idx : int = libres[randi() % libres.size()]
	chaises[idx]["occupee"] = true
	nb_clients += 1

	var client = CLIENT_SCENE.instantiate()
	add_child(client)
	client.global_position = chaises[idx]["position"]

	var look_pos = chaises[idx]["look_at"]
	look_pos.y   = client.global_position.y
	client.look_at(look_pos)

	client.servi.connect(_on_client_servi.bind(idx))
	client.parti.connect(_on_client_parti.bind(idx))
	client.tue.connect(_on_client_tue.bind(idx))

	_programmer_prochain_spawn()

# ── Signaux clients ───────────────────────────────────────────
func _on_client_servi(correct: bool, idx: int) -> void:
	chaises[idx]["occupee"] = false
	nb_clients -= 1
	_modifier_score(50 if correct else -20)
	_verifier_remplacement()

func _on_client_parti(idx: int) -> void:
	chaises[idx]["occupee"] = false
	nb_clients -= 1
	_modifier_score(-50)
	_verifier_remplacement()

func _on_client_tue(idx: int) -> void:
	chaises[idx]["occupee"] = false
	nb_clients -= 1
	_modifier_score(-150)
	_verifier_remplacement()

# ── Score ─────────────────────────────────────────────────────
func _modifier_score(delta: int) -> void:
	score += delta
	if score_ui != null:
		score_ui.mettre_a_jour(score, delta)
	if score < SEUIL_DEFAITE:
		_declencher_defaite()

func _declencher_defaite() -> void:
	timer_spawn.stop()
	var bs = get_node_or_null("/root/BestScore")
	if bs:
		bs.update(score)
	if game_over_screen != null:
		game_over_screen.afficher(score)

# ── Remplace si en-dessous du minimum ────────────────────────
func _verifier_remplacement() -> void:
	if nb_clients < MIN_CLIENTS:
		var t       = Timer.new()
		t.wait_time = DELAI_REMPLACEMENT
		t.one_shot  = true
		add_child(t)
		t.timeout.connect(func():
			_spawner_client()
			t.queue_free()
		)
		t.start()

func _liberer_chaise(idx: int) -> void:
	chaises[idx]["occupee"] = false

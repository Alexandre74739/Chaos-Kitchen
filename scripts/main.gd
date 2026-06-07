extends Node3D

const CLIENT_SCENE = preload("res://entities/personnages/client.tscn")
const SPAWN_MIN    = 15.0
const SPAWN_MAX    = 30.0
const MIN_CLIENTS  = 2
const DELAI_REMPLACEMENT = 4.0

var chaises      : Array = []
var timer_spawn  : Timer
var nb_clients   : int   = 0

func _ready():
	AudioManager.jouer_ambiance("ambiance")
	_collecter_chaises()
	_lancer_timer_spawn()
	for i in range(MIN_CLIENTS):
		_spawner_client()

# ── Collecte toutes les positions de chaises dans la salle ──
func _collecter_chaises():
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

# ── Démarre le cycle de spawn périodique ────────────────────
func _lancer_timer_spawn():
	timer_spawn          = Timer.new()
	timer_spawn.one_shot = true
	add_child(timer_spawn)
	timer_spawn.timeout.connect(_spawner_client)
	_programmer_prochain_spawn()

func _programmer_prochain_spawn():
	timer_spawn.wait_time = randf_range(SPAWN_MIN, SPAWN_MAX)
	timer_spawn.start()

# ── Choisit une chaise libre et y installe un client ─────────
func _spawner_client():
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

	client.servi.connect(_on_client_quitte.bind(idx))
	client.parti.connect(_on_client_quitte.bind(idx))

	_programmer_prochain_spawn()

# ── Libère la chaise et remplace si en-dessous du minimum ───
func _on_client_quitte(idx: int):
	chaises[idx]["occupee"] = false
	nb_clients -= 1
	if nb_clients < MIN_CLIENTS:
		var t          = Timer.new()
		t.wait_time    = DELAI_REMPLACEMENT
		t.one_shot     = true
		add_child(t)
		t.timeout.connect(func():
			_spawner_client()
			t.queue_free()
		)
		t.start()

func _liberer_chaise(idx: int):
	chaises[idx]["occupee"] = false

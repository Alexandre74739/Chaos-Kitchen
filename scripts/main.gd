extends Node3D

const CLIENT_SCENE        = preload("res://entities/personnages/client.tscn")
const FONT                = preload("res://assets/fonts/MatchaCih.ttf")
const SCORE_UI_SCRIPT     = "res://scripts/score_ui.gd"
const PAUSE_MENU_SCRIPT   = "res://scripts/pause_menu.gd"
const GAME_OVER_SCRIPT    = "res://scripts/game_over.gd"
const RAT_SCRIPT          = "res://scripts/rat.gd"

# ── Clients ───────────────────────────────────────────────────────────
const SPAWN_MIN            = 15.0
const SPAWN_MAX            = 30.0
const MIN_CLIENTS          = 2
const MAX_CLIENTS          = 8
const DELAI_REMPLACEMENT   = 4.0
const SEUIL_DEFAITE        = -500
const SEUIL_CLIENTS_PERDUS = 5

# ── Rats ──────────────────────────────────────────────────────────────
const MAX_RATS             = 6
const SPAWN_RAT_MIN        = 18.0
const SPAWN_RAT_MAX        = 28.0

# ── Inspecteur ────────────────────────────────────────────────────────
const INSPECTEUR_MIN       = 45.0
const INSPECTEUR_MAX       = 80.0
const DUREE_INSPECTION     = 12.0
const BONUS_INSPECTION     = 250

const ZONES_RATS = [
	Vector3(3.0, 0.1,  -6.0),
	Vector3(5.5, 0.1,  -5.5),
	Vector3(7.0, 0.1,  -7.5),
	Vector3(2.5, 0.1,  -8.5),
	Vector3(6.0, 0.1,  -9.5),
	Vector3(4.0, 0.1, -10.5),
	Vector3(4.5, 0.1, -13.0),
	Vector3(6.0, 0.1, -14.0),
	Vector3(3.0, 0.1, -15.5),
	Vector3(5.5, 0.1, -16.5),
	Vector3(2.0, 0.1, -17.0),
]

# ── État du jeu ───────────────────────────────────────────────────────
var chaises              : Array = []
var timer_spawn          : Timer
var nb_clients           : int   = 0
var score                : int   = 0
var clients_perdus       : int   = 0
var rats_vivants         : int   = 0
var _defaite_declenchee  : bool  = false

var score_ui             : Node  = null
var pause_menu           : Node  = null
var game_over_screen     : Node  = null

# ── Rats ──────────────────────────────────────────────────────────────
var timer_rat            : Timer = null
var _inspection_active   : bool  = false

# ── Inspecteur ────────────────────────────────────────────────────────
var timer_inspecteur         : Timer       = null
var _inspector_initial_wait  : float       = 0.0
var _inspection_hud          : CanvasLayer = null
var _lbl_countdown           : Label       = null
var _lbl_rats_insp           : Label       = null
var _temps_restant           : float       = 0.0
var _tween_inspection        : Tween       = null

# ── HUD permanent ─────────────────────────────────────────────────────
var _hud_permanent           : CanvasLayer  = null
var _lbl_rats_permanent      : Label        = null
var _container_inspecteur    : Control      = null
var _bar_inspecteur          : ProgressBar  = null
var _bar_fill_sty            : StyleBoxFlat = null

# ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	AudioManager.jouer_ambiance("ambiance")
	_collecter_chaises()
	_lancer_timer_spawn()
	_creer_score_ui()
	_creer_pause_menu()
	_creer_game_over()
	_creer_hud_permanent()
	_lancer_timer_rats()
	_lancer_timer_inspecteur()
	for i in range(MIN_CLIENTS):
		_spawner_client()

func _process(_delta: float) -> void:
	if _bar_inspecteur == null or _defaite_declenchee:
		return
	if _container_inspecteur == null or not _container_inspecteur.visible:
		return
	if _inspector_initial_wait <= 0.0:
		return

	var pct = 1.0 - clamp(timer_inspecteur.time_left / _inspector_initial_wait, 0.0, 1.0)
	_bar_inspecteur.value = pct * 100.0

	if _bar_fill_sty:
		if pct < 0.5:
			_bar_fill_sty.bg_color = Color(0.20, 0.60, 1.00, 1.0)
		elif pct < 0.75:
			_bar_fill_sty.bg_color = Color(1.00, 0.72, 0.00, 1.0)
		else:
			_bar_fill_sty.bg_color = Color(1.00, 0.20, 0.20, 1.0)

# ── Score UI ──────────────────────────────────────────────────────────
func _creer_score_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.set_script(load(SCORE_UI_SCRIPT))
	add_child(canvas)
	score_ui = canvas

# ── Menu Pause ────────────────────────────────────────────────────────
func _creer_pause_menu() -> void:
	var canvas = CanvasLayer.new()
	canvas.set_script(load(PAUSE_MENU_SCRIPT))
	add_child(canvas)
	pause_menu = canvas

# ── Écran Game Over ───────────────────────────────────────────────────
func _creer_game_over() -> void:
	var canvas = CanvasLayer.new()
	canvas.set_script(load(GAME_OVER_SCRIPT))
	add_child(canvas)
	game_over_screen = canvas

# ── HUD permanent : rats + barre inspecteur ───────────────────────────
func _creer_hud_permanent() -> void:
	_hud_permanent       = CanvasLayer.new()
	_hud_permanent.layer = 22
	add_child(_hud_permanent)

	var f = get_viewport().get_visible_rect().size.y / 1080.0

	# ── Compteur de rats (sous le score, en haut à gauche) ─
	var rat_panel = PanelContainer.new()
	rat_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	rat_panel.offset_left = int(24 * f)
	rat_panel.offset_top  = int(220 * f)

	var sty_r = StyleBoxFlat.new()
	sty_r.bg_color                   = Color(0.07, 0.07, 0.22, 0.82)
	sty_r.corner_radius_top_left     = 20
	sty_r.corner_radius_top_right    = 20
	sty_r.corner_radius_bottom_left  = 20
	sty_r.corner_radius_bottom_right = 20
	sty_r.border_color               = Color(0.90, 0.15, 0.15, 1.0)
	sty_r.border_width_left          = 4
	sty_r.border_width_right         = 4
	sty_r.border_width_top           = 4
	sty_r.border_width_bottom        = 4
	sty_r.content_margin_left        = int(18 * f)
	sty_r.content_margin_right       = int(18 * f)
	sty_r.content_margin_top         = int(8 * f)
	sty_r.content_margin_bottom      = int(10 * f)
	rat_panel.add_theme_stylebox_override("panel", sty_r)
	_hud_permanent.add_child(rat_panel)

	var vbox_r = VBoxContainer.new()
	vbox_r.alignment = BoxContainer.ALIGNMENT_CENTER
	rat_panel.add_child(vbox_r)

	var lbl_titre_rat = Label.new()
	lbl_titre_rat.text                 = "RATS"
	lbl_titre_rat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var st_r = LabelSettings.new()
	st_r.font          = FONT
	st_r.font_size     = int(28 * f)
	st_r.font_color    = Color(1.0, 0.40, 0.40, 1.0)
	st_r.outline_size  = 5
	st_r.outline_color = Color(0, 0, 0, 1)
	lbl_titre_rat.label_settings = st_r
	vbox_r.add_child(lbl_titre_rat)

	_lbl_rats_permanent = Label.new()
	_lbl_rats_permanent.text                 = "0"
	_lbl_rats_permanent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_rats_permanent.custom_minimum_size  = Vector2(int(130 * f), 0)
	var ss_r = LabelSettings.new()
	ss_r.font          = FONT
	ss_r.font_size     = int(88 * f)
	ss_r.font_color    = Color(1.0, 1.0, 0.2, 1.0)
	ss_r.outline_size  = 9
	ss_r.outline_color = Color(0, 0, 0, 1)
	_lbl_rats_permanent.label_settings = ss_r
	vbox_r.add_child(_lbl_rats_permanent)

	# ── Barre d'arrivée de l'inspecteur (haut centre) ──────
	_container_inspecteur = Control.new()
	_container_inspecteur.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_hud_permanent.add_child(_container_inspecteur)

	var bar_panel = PanelContainer.new()
	var half_w = int(240 * f)
	bar_panel.anchor_left   = 0.5
	bar_panel.anchor_right  = 0.5
	bar_panel.anchor_top    = 0.0
	bar_panel.anchor_bottom = 0.0
	bar_panel.offset_left   = -half_w
	bar_panel.offset_right  = half_w
	bar_panel.offset_top    = int(8 * f)

	var sty_b = StyleBoxFlat.new()
	sty_b.bg_color                   = Color(0.07, 0.07, 0.22, 0.85)
	sty_b.corner_radius_top_left     = 14
	sty_b.corner_radius_top_right    = 14
	sty_b.corner_radius_bottom_left  = 14
	sty_b.corner_radius_bottom_right = 14
	sty_b.border_color               = Color(0.4, 0.4, 1.0, 0.6)
	sty_b.border_width_left          = 3
	sty_b.border_width_right         = 3
	sty_b.border_width_top           = 3
	sty_b.border_width_bottom        = 3
	sty_b.content_margin_left        = int(14 * f)
	sty_b.content_margin_right       = int(14 * f)
	sty_b.content_margin_top         = int(8 * f)
	sty_b.content_margin_bottom      = int(10 * f)
	bar_panel.add_theme_stylebox_override("panel", sty_b)
	_container_inspecteur.add_child(bar_panel)

	var vbox_b = VBoxContainer.new()
	vbox_b.add_theme_constant_override("separation", int(4 * f))
	bar_panel.add_child(vbox_b)

	var lbl_insp = _lbl_hud("Inspecteur", int(22 * f), Color(0.75, 0.75, 1.0, 0.90))
	vbox_b.add_child(lbl_insp)

	_bar_inspecteur                     = ProgressBar.new()
	_bar_inspecteur.min_value           = 0.0
	_bar_inspecteur.max_value           = 100.0
	_bar_inspecteur.value               = 0.0
	_bar_inspecteur.show_percentage     = false
	_bar_inspecteur.custom_minimum_size = Vector2(0, int(22 * f))
	_bar_inspecteur.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg_sty = StyleBoxFlat.new()
	bg_sty.bg_color                   = Color(0.15, 0.15, 0.35, 1.0)
	bg_sty.corner_radius_top_left     = 8
	bg_sty.corner_radius_top_right    = 8
	bg_sty.corner_radius_bottom_left  = 8
	bg_sty.corner_radius_bottom_right = 8
	_bar_inspecteur.add_theme_stylebox_override("background", bg_sty)

	_bar_fill_sty = StyleBoxFlat.new()
	_bar_fill_sty.bg_color                   = Color(0.2, 0.6, 1.0, 1.0)
	_bar_fill_sty.corner_radius_top_left     = 8
	_bar_fill_sty.corner_radius_top_right    = 8
	_bar_fill_sty.corner_radius_bottom_left  = 8
	_bar_fill_sty.corner_radius_bottom_right = 8
	_bar_inspecteur.add_theme_stylebox_override("fill", _bar_fill_sty)

	vbox_b.add_child(_bar_inspecteur)

# ── Collecte toutes les positions de chaises dans la salle ───────────
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

# ── Cycle de spawn clients ────────────────────────────────────────────
func _lancer_timer_spawn() -> void:
	timer_spawn          = Timer.new()
	timer_spawn.one_shot = true
	add_child(timer_spawn)
	timer_spawn.timeout.connect(_spawner_client)
	_programmer_prochain_spawn()

func _programmer_prochain_spawn() -> void:
	timer_spawn.wait_time = randf_range(SPAWN_MIN, SPAWN_MAX)
	timer_spawn.start()

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

# ── Signaux clients ───────────────────────────────────────────────────
func _on_client_servi(correct: bool, idx: int) -> void:
	chaises[idx]["occupee"] = false
	nb_clients -= 1
	_modifier_score(50 if correct else -20)
	if correct:
		clients_perdus = max(0, clients_perdus - 1)
	_verifier_remplacement()

func _on_client_parti(idx: int) -> void:
	chaises[idx]["occupee"] = false
	nb_clients -= 1
	clients_perdus += 1
	_modifier_score(-50)
	_verifier_clients_perdus()
	_verifier_remplacement()

func _on_client_tue(idx: int) -> void:
	chaises[idx]["occupee"] = false
	nb_clients -= 1
	clients_perdus += 1
	_modifier_score(-150)
	_verifier_clients_perdus()
	_verifier_remplacement()

# ── Vérification patience clients ─────────────────────────────────────
func _verifier_clients_perdus() -> void:
	if clients_perdus >= SEUIL_CLIENTS_PERDUS:
		_declencher_defaite("Trop de clients ont perdu patience !")

# ── Score ─────────────────────────────────────────────────────────────
func _modifier_score(delta: int) -> void:
	score += delta
	if score_ui != null:
		score_ui.mettre_a_jour(score, delta)
	if score < SEUIL_DEFAITE:
		_declencher_defaite("Score trop bas : les finances sont dans le rouge !")

func _declencher_defaite(raison: String) -> void:
	if _defaite_declenchee:
		return
	_defaite_declenchee = true

	timer_spawn.stop()
	if timer_rat:
		timer_rat.stop()
	if timer_inspecteur:
		timer_inspecteur.stop()
	if _tween_inspection:
		_tween_inspection.kill()
		_tween_inspection = null
	if _inspection_hud:
		_inspection_hud.queue_free()
		_inspection_hud = null
	if _hud_permanent:
		_hud_permanent.visible = false

	if game_over_screen != null:
		game_over_screen.afficher(score, raison)

# ── Remplace si en-dessous du minimum ────────────────────────────────
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

# ── Système de rats ───────────────────────────────────────────────────
func _lancer_timer_rats() -> void:
	timer_rat          = Timer.new()
	timer_rat.one_shot = true
	add_child(timer_rat)
	timer_rat.timeout.connect(_spawner_rat)
	_programmer_prochain_rat()

func _programmer_prochain_rat(min_t: float = SPAWN_RAT_MIN, max_t: float = SPAWN_RAT_MAX) -> void:
	timer_rat.wait_time = randf_range(min_t, max_t)
	timer_rat.start()

func _spawner_rat() -> void:
	if not _defaite_declenchee and not _inspection_active and rats_vivants < MAX_RATS:
		var zone   = ZONES_RATS[randi() % ZONES_RATS.size()]
		var offset = Vector3(randf_range(-0.5, 0.5), 0.0, randf_range(-0.5, 0.5))
		var rat    = CharacterBody3D.new()
		rat.set_script(load(RAT_SCRIPT))
		rat.position = zone + offset
		add_child(rat)
		rat.mort.connect(_on_rat_mort)
		rats_vivants += 1
		_maj_hud_rats()

	if not _defaite_declenchee and not _inspection_active:
		_programmer_prochain_rat()

func _on_rat_mort() -> void:
	rats_vivants = max(0, rats_vivants - 1)
	_maj_hud_rats()

func _maj_hud_rats() -> void:
	if _lbl_rats_insp:
		_lbl_rats_insp.text = "Rats : " + str(rats_vivants)
	if _lbl_rats_permanent:
		_lbl_rats_permanent.text = str(rats_vivants)

# ── Système d'inspecteur ──────────────────────────────────────────────
func _lancer_timer_inspecteur() -> void:
	timer_inspecteur          = Timer.new()
	timer_inspecteur.one_shot = true
	add_child(timer_inspecteur)
	timer_inspecteur.timeout.connect(_arrivee_inspecteur)
	_programmer_prochain_inspecteur()

func _programmer_prochain_inspecteur() -> void:
	var t                   = randf_range(INSPECTEUR_MIN, INSPECTEUR_MAX)
	_inspector_initial_wait = t
	timer_inspecteur.wait_time = t
	timer_inspecteur.start()
	if _container_inspecteur:
		_container_inspecteur.visible = true

func _arrivee_inspecteur() -> void:
	if _defaite_declenchee:
		return
	_inspection_active = true
	if timer_rat:
		timer_rat.stop()
	if _container_inspecteur:
		_container_inspecteur.visible = false
	_afficher_hud_inspection()

func _afficher_hud_inspection() -> void:
	_temps_restant  = DUREE_INSPECTION
	_inspection_hud = CanvasLayer.new()
	_inspection_hud.layer = 45
	add_child(_inspection_hud)

	var f = get_viewport().get_visible_rect().size.y / 1080.0

	var banner = PanelContainer.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banner.custom_minimum_size = Vector2(0, int(100 * f))
	var sty = StyleBoxFlat.new()
	sty.bg_color              = Color(0.65, 0.04, 0.04, 0.93)
	sty.content_margin_left   = int(30 * f)
	sty.content_margin_right  = int(30 * f)
	sty.content_margin_top    = int(10 * f)
	sty.content_margin_bottom = int(10 * f)
	banner.add_theme_stylebox_override("panel", sty)
	_inspection_hud.add_child(banner)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", int(50 * f))
	banner.add_child(hbox)

	hbox.add_child(_lbl_hud("⚠  INSPECTION SANITAIRE !", int(42 * f), Color(1.0, 0.92, 0.15, 1.0)))

	var sep = VSeparator.new()
	sep.custom_minimum_size = Vector2(int(3 * f), 0)
	var sty_sep = StyleBoxFlat.new()
	sty_sep.bg_color = Color(1.0, 1.0, 1.0, 0.3)
	sep.add_theme_stylebox_override("separator", sty_sep)
	hbox.add_child(sep)

	_lbl_rats_insp = _lbl_hud("Rats : " + str(rats_vivants), int(36 * f), Color(1.0, 0.6, 0.6, 1.0))
	hbox.add_child(_lbl_rats_insp)

	_lbl_countdown = _lbl_hud("Temps : " + str(int(_temps_restant)) + "s", int(36 * f), Color(1.0, 1.0, 1.0, 1.0))
	hbox.add_child(_lbl_countdown)

	var timer_fin       = Timer.new()
	timer_fin.wait_time = DUREE_INSPECTION
	timer_fin.one_shot  = true
	_inspection_hud.add_child(timer_fin)
	timer_fin.timeout.connect(_fin_inspection)
	timer_fin.start()

	var tick       = Timer.new()
	tick.wait_time = 1.0
	tick.one_shot  = false
	_inspection_hud.add_child(tick)
	tick.timeout.connect(func():
		_temps_restant -= 1.0
		if _lbl_countdown:
			_lbl_countdown.text = "Temps : " + str(max(0, int(_temps_restant))) + "s"
			if _temps_restant <= 5.0:
				_lbl_countdown.modulate = Color(1.0, 0.25, 0.25, 1.0)
	)
	tick.start()

	_tween_inspection = create_tween().set_loops()
	_tween_inspection.tween_property(banner, "modulate:a", 0.72, 0.45)
	_tween_inspection.tween_property(banner, "modulate:a", 1.0,  0.45)

func _fin_inspection() -> void:
	if _tween_inspection:
		_tween_inspection.kill()
		_tween_inspection = null
	if _inspection_hud:
		_inspection_hud.queue_free()
		_inspection_hud = null
	_lbl_countdown = null
	_lbl_rats_insp = null

	if _defaite_declenchee:
		return

	if rats_vivants > 0:
		_declencher_defaite("Fermeture sanitaire : L'inspecteur a trouvé des rats !")
	else:
		_inspection_active = false
		_modifier_score(BONUS_INSPECTION)
		AudioManager.jouer_sfx("win_pts")
		_programmer_prochain_rat(3.0, 12.0)
		_programmer_prochain_inspecteur()

# ── Helper label HUD ──────────────────────────────────────────────────
func _lbl_hud(texte: String, taille: int, couleur: Color) -> Label:
	var l = Label.new()
	l.text                 = texte
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var s = LabelSettings.new()
	s.font          = FONT
	s.font_size     = taille
	s.font_color    = couleur
	s.outline_size  = 5
	s.outline_color = Color(0, 0, 0, 1)
	l.label_settings = s
	return l

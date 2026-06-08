extends Node3D

const FONT              = preload("res://assets/fonts/MatchaCih.ttf")
const SOL_SCENE         = preload("res://decor/sol.tscn")
const DECO_SCENE        = preload("res://decor/cuisineDecoAngle.tscn")
const LUIGI_GLB         = preload("res://assets/Luigi.glb")
const PLAN_SCENE        = preload("res://entities/items/plan_travail.tscn")
const BAC_PAIN_SCENE    = preload("res://decor/bacPain.tscn")
const BAC_TOMATE_SCENE  = preload("res://decor/bacTomate.tscn")
const BAC_VIANDE_SCENE  = preload("res://decor/bacViande.tscn")
const FRIDGE_SCENE      = preload("res://assets/fridge_A.fbx")
const TABLE_SCENE       = preload("res://assets/kitchentable_A_large.fbx")

const C_BG    := Color(0.05, 0.05, 0.18, 0.96)
const C_OR    := Color(1.0,  0.72, 0.0,  1.0)
const C_OR2   := Color(1.0,  0.88, 0.45, 1.0)
const C_JAUNE := Color(1.0,  1.0,  0.2,  1.0)
const C_BTN_N := Color(0.15, 0.15, 0.40, 1.0)
const C_BTN_H := Color(0.28, 0.28, 0.65, 1.0)

var _label_best        : Label   = null
var _sous_panel        : Control = null
var _btn_jouer         : Button  = null
var _btn_overlay_focus : Button  = null


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_setup_world()
	_setup_player()
	_setup_camera()
	_setup_ui()

# ── MONDE 3D ──────────────────────────────────────────────────────

func _setup_world() -> void:
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color        = Color(0.28, 0.16, 0.07)
	sky_mat.sky_horizon_color    = Color(0.62, 0.42, 0.18)
	sky_mat.ground_horizon_color = Color(0.62, 0.42, 0.18)
	sky_mat.ground_bottom_color  = Color(0.12, 0.08, 0.04)
	var sky = Sky.new()
	sky.sky_material = sky_mat
	var env = Environment.new()
	env.background_mode      = Environment.BG_SKY
	env.sky                  = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.tonemap_mode         = Environment.TONE_MAPPER_ACES
	var we = WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, 28.0, 0.0)
	sun.light_color      = Color(1.0, 0.94, 0.80)
	sun.light_energy     = 1.5
	sun.shadow_enabled   = false
	add_child(sun)

	var omni = OmniLight3D.new()
	omni.position     = Vector3(2.0, 5.0, 1.5)
	omni.light_color  = Color(1.0, 0.92, 0.72)
	omni.light_energy = 2.5
	omni.omni_range   = 18.0
	add_child(omni)

	var omni2 = OmniLight3D.new()
	omni2.position     = Vector3(-3.0, 4.0, 4.0)
	omni2.light_color  = Color(0.85, 0.90, 1.0)
	omni2.light_energy = 0.9
	omni2.omni_range   = 12.0
	add_child(omni2)

	# Murs de fond et latéral
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.88, 0.82, 0.70, 1.0)
	wall_mat.roughness    = 0.88

	var wall_back = MeshInstance3D.new()
	var back_mesh = PlaneMesh.new()
	back_mesh.size        = Vector2(22.0, 7.5)
	back_mesh.orientation = PlaneMesh.FACE_Z
	wall_back.mesh              = back_mesh
	wall_back.material_override = wall_mat
	wall_back.position          = Vector3(2.0, 3.0, -5.5)
	add_child(wall_back)

	var wall_left = MeshInstance3D.new()
	var left_mesh = PlaneMesh.new()
	left_mesh.size        = Vector2(10.0, 7.5)
	left_mesh.orientation = PlaneMesh.FACE_X
	wall_left.mesh              = left_mesh
	wall_left.material_override = wall_mat
	wall_left.position          = Vector3(-5.5, 3.0, 0.0)
	add_child(wall_left)

	# Sol
	var sol = SOL_SCENE.instantiate()
	sol.rotation_degrees.y = 90.0
	sol.position           = Vector3(2.0, 0.0, 0.0)
	add_child(sol)

	# Coin cuisine (comptoirs, plaque, hotte, évier) — fond gauche
	var deco = DECO_SCENE.instantiate()
	deco.position = Vector3(-3.5, 0.0, -4.0)
	add_child(deco)

	# Réfrigérateur contre le mur gauche — bien visible depuis la caméra
	var fridge = FRIDGE_SCENE.instantiate()
	fridge.position           = Vector3(-4.5, 0.0, -2.5)
	fridge.rotation_degrees.y = 90.0
	add_child(fridge)

	# Grande table de cuisine — arrière droit
	var table = TABLE_SCENE.instantiate()
	table.position = Vector3(5.0, 0.0, -3.0)
	add_child(table)

	# Plan de travail — juste derrière le player, au centre
	var plan = PLAN_SCENE.instantiate()
	plan.position = Vector3(1.5, 0.0, -2.0)
	add_child(plan)

	# Bacs d'ingrédients — sur le plan de travail et aux alentours
	var bac_pain = BAC_PAIN_SCENE.instantiate()
	bac_pain.position = Vector3(0.5, 0.5, -3.0)
	add_child(bac_pain)

	var bac_tomate = BAC_TOMATE_SCENE.instantiate()
	bac_tomate.position = Vector3(2.5, 0.5, -3.5)
	add_child(bac_tomate)

	var bac_viande = BAC_VIANDE_SCENE.instantiate()
	bac_viande.position = Vector3(-0.8, 0.5, -3.2)
	add_child(bac_viande)


func _setup_player() -> void:
	var pivot = Node3D.new()
	pivot.name       = "PlayerDisplay"
	pivot.position   = Vector3(3.2, 0.0, 0.5)
	pivot.rotation.y = PI + 0.30
	add_child(pivot)

	var luigi = LUIGI_GLB.instantiate()
	luigi.scale = Vector3(0.62, 0.62, 0.62)
	luigi.transform.basis = Basis(
		Vector3(-4.3711392e-08, 0.0, 1.0),
		Vector3(0.0,            1.0, 0.0),
		Vector3(-1.0,           0.0, -4.3711392e-08)
	)
	luigi.position = Vector3(0.0, -0.4823, 0.0)
	pivot.add_child(luigi)

	var lib   = AnimationLibrary.new()
	var reset = Animation.new()
	reset.length = 0.001
	var tr = reset.add_track(Animation.TYPE_VALUE)
	reset.track_set_path(tr, NodePath(".:position"))
	reset.track_insert_key(tr, 0.0, Vector3.ZERO)
	lib.add_animation("RESET", reset)

	var idle = Animation.new()
	idle.resource_name = "idle_organic"
	idle.length        = 2.0
	idle.loop_mode     = Animation.LOOP_LINEAR
	var ti = idle.add_track(Animation.TYPE_VALUE)
	idle.track_set_path(ti, NodePath(".:position"))
	idle.track_set_interpolation_type(ti, Animation.INTERPOLATION_LINEAR)
	idle.track_insert_key(ti, 0.0, Vector3(0.0, 0.0,  0.0))
	idle.track_insert_key(ti, 0.5, Vector3(0.0, 0.05, 0.0))
	idle.track_insert_key(ti, 1.0, Vector3(0.0, 0.0,  0.0))
	idle.track_insert_key(ti, 1.5, Vector3(0.0, 0.10, 0.0))
	idle.track_insert_key(ti, 2.0, Vector3(0.0, 0.0,  0.0))
	lib.add_animation("idle_organic", idle)

	var ap = AnimationPlayer.new()
	ap.add_animation_library("", lib)
	pivot.add_child(ap)
	ap.play("idle_organic")


func _setup_camera() -> void:
	var cam = Camera3D.new()
	cam.fov      = 52.0
	cam.position = Vector3(-2.0, 2.0, 7.5)
	add_child(cam)
	cam.look_at(Vector3(3.0, 1.1, 0.2), Vector3.UP)


# ── UI ────────────────────────────────────────────────────────────

func _setup_ui() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	root.add_child(_creer_panneau_gauche())

	_sous_panel = Control.new()
	_sous_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sous_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sous_panel.visible = false
	root.add_child(_sous_panel)

	# Focus initial sur JOUER (pour navigation manette)
	if _btn_jouer:
		_btn_jouer.call_deferred("grab_focus")


func _creer_panneau_gauche() -> Control:
	var f = get_viewport().get_visible_rect().size.y / 1080.0

	var panel = PanelContainer.new()
	panel.anchor_right  = 0.33
	panel.anchor_bottom = 1.0

	var sty = StyleBoxFlat.new()
	sty.bg_color           = C_BG
	sty.border_color       = C_OR
	sty.border_width_right = 5
	sty.content_margin_left   = int(44 * f)
	sty.content_margin_right  = int(44 * f)
	sty.content_margin_top    = int(60 * f)
	sty.content_margin_bottom = int(60 * f)
	panel.add_theme_stylebox_override("panel", sty)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", int(16 * f))
	panel.add_child(vbox)

	vbox.add_child(_lbl("CHAOS",   int(98 * f), C_OR, 14))
	vbox.add_child(_lbl("KITCHEN", int(98 * f), C_OR, 14))
	vbox.add_child(_sep(f))

	vbox.add_child(_lbl("MEILLEUR SCORE", int(26 * f), C_OR2, 4))
	_label_best = _lbl(str(BestScore.get_best()), int(64 * f), C_JAUNE, 9)
	vbox.add_child(_label_best)
	vbox.add_child(_sep(f))

	_btn_jouer = _btn("JOUER", f, true)
	_btn_jouer.pressed.connect(_on_jouer)
	vbox.add_child(_btn_jouer)

	for row in [["RÈGLES", _on_regles], ["PARAMÈTRES", _on_parametres], ["CRÉDITS", _on_credits]]:
		var b = _btn(row[0], f, false)
		b.pressed.connect(row[1])
		vbox.add_child(b)
		
	var btn_quitter = _btn("QUITTER", f, false)
	btn_quitter.pressed.connect(_on_quitter)
	vbox.add_child(btn_quitter)

	# Hint manette
	var hint = _lbl("Manette : D-Pad naviguer  ·  A/Croix sélectionner",
		int(18 * f), Color(0.75, 0.75, 0.60, 0.75), 3)
	vbox.add_child(hint)

	return panel


# ── Actions ───────────────────────────────────────────────────────

func _on_jouer() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_regles() -> void:
	_afficher_sous_panel(_construire_regles())

func _on_parametres() -> void:
	_afficher_sous_panel(_construire_parametres())

func _on_credits() -> void:
	_afficher_sous_panel(_construire_credits())
	
func _on_quitter() -> void:
	get_tree().quit()

func _afficher_sous_panel(contenu: Control) -> void:
	for c in _sous_panel.get_children():
		c.queue_free()
	_sous_panel.add_child(contenu)
	_sous_panel.visible = true
	if _btn_overlay_focus:
		_btn_overlay_focus.call_deferred("grab_focus")

func _fermer_sous_panel() -> void:
	_btn_overlay_focus = null
	_sous_panel.visible = false
	for c in _sous_panel.get_children():
		c.queue_free()
	if _btn_jouer:
		_btn_jouer.call_deferred("grab_focus")


# ── Fabrique panneau centré avec scroll ───────────────────────────
# Retourne [fond_global, outer_vbox, scroll_vbox]
# outer_vbox  = conteneur principal du panneau (titre, bouton fermer vont ici)
# scroll_vbox = conteneur à l'intérieur du ScrollContainer (contenu scrollable)

func _creer_panneau_overlay(largeur_px: int, f: float) -> Array:
	var fond = ColorRect.new()
	fond.color = Color(0, 0, 0, 0.68)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centre = CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.add_child(centre)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(int(largeur_px * f), 0)
	var sty = StyleBoxFlat.new()
	sty.bg_color                   = Color(0.07, 0.07, 0.22, 0.97)
	sty.corner_radius_top_left     = 26
	sty.corner_radius_top_right    = 26
	sty.corner_radius_bottom_left  = 26
	sty.corner_radius_bottom_right = 26
	sty.border_color               = C_OR
	sty.border_width_left          = 5
	sty.border_width_right         = 5
	sty.border_width_top           = 5
	sty.border_width_bottom        = 5
	sty.content_margin_left        = int(58 * f)
	sty.content_margin_right       = int(58 * f)
	sty.content_margin_top         = int(46 * f)
	sty.content_margin_bottom      = int(50 * f)
	panel.add_theme_stylebox_override("panel", sty)
	centre.add_child(panel)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", int(10 * f))
	panel.add_child(outer)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size    = Vector2(0, int(440 * f))
	scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", int(10 * f))
	scroll.add_child(scroll_vbox)

	return [fond, outer, scroll_vbox, scroll]


# ── Règles ────────────────────────────────────────────────────────

func _construire_regles() -> Control:
	var f    = get_viewport().get_visible_rect().size.y / 1080.0
	var base = _creer_panneau_overlay(920, f)
	var fond       : Control       = base[0]
	var outer      : VBoxContainer = base[1]
	var vbox       : VBoxContainer = base[2]
	var scroll     : ScrollContainer = base[3]

	# Titre (fixe, hors scroll)
	outer.add_child(_lbl("RÈGLES", int(72 * f), C_OR, 10))
	outer.add_child(_sep(f))
	outer.add_child(scroll)

	# ── Contenu scrollable ────────────────────────────────
	vbox.add_child(_entete("OBJECTIF", f))
	vbox.add_child(_corps("Prépare et livre des burgers aux clients avant\nqu'ils perdent patience !", f))
	vbox.add_child(_sep(f))

	vbox.add_child(_entete("DÉPLACEMENTS", f))
	vbox.add_child(_corps(
		"Clavier\n" +
		"   Z / Q / S / D     Se déplacer\n" +
		"   Souris                Orienter la caméra\n" +
		"   Échap                 Menu Pause\n\n" +
		"Manette\n" +
		"   Stick gauche       Se déplacer\n" +
		"   Stick droit          Orienter la caméra\n" +
		"   Start / Options    Menu Pause", f))
	vbox.add_child(_sep(f))

	vbox.add_child(_entete("ACTIONS", f))
	vbox.add_child(_corps(
		"Clavier\n" +
		"   E                        Ramasser / Livrer un burger\n" +
		"   Clic droit          Tirer (avec le fusil)\n" +
		"   Clic gauche             Viser — zoom FOV + réticule\n\n" +
		"Manette\n" +
		"   A / Croix              Ramasser / Livrer un burger\n" +
		"   Gâchette droite   Tirer (avec le fusil)\n" +
		"   Gâchette gauche  Viser — zoom FOV + réticule", f))
	vbox.add_child(_sep(f))

	vbox.add_child(_entete("ASSEMBLER UN BURGER", f))
	vbox.add_child(_corps(
		"1.  Ramasse les ingrédients dans les bacs\n" +
		"2.  Dépose-les dans l'ordre sur le plan de travail :\n" +
		"        pain bas  →  ingrédients  →  pain haut\n" +
		"3.  Apporte le burger au client et appuie sur E / A", f))
	vbox.add_child(_sep(f))

	vbox.add_child(_entete("RATS & INSPECTEUR", f))
	vbox.add_child(_corps(
		"Des rats envahissent la cuisine au fil du temps.\n" +
		"Élimine-les avec le fusil avant l'arrivée de l'inspecteur.\n\n" +
		"La barre en haut indique l'approche de l'inspecteur.\n" +
		"Si des rats sont présents lors de l'inspection → fermeture sanitaire !\n" +
		"Cuisine propre : +250 points", f))
	vbox.add_child(_sep(f))

	vbox.add_child(_entete("SCORE", f))
	vbox.add_child(_corps(
		"+50      Bonne commande livrée\n" +
		"−20      Mauvaise commande\n" +
		"−50      Client parti sans être servi\n" +
		"−150    Client éliminé avec le fusil\n" +
		"+250    Inspection sanitaire réussie\n\n" +
		"Game Over si score ≤ −500\n" +
		"Game Over si 5 clients perdent patience", f))

	# Bouton FERMER (fixe, hors scroll)
	outer.add_child(_sep(f))
	var btn = _btn("FERMER", f, false)
	btn.pressed.connect(_fermer_sous_panel)
	outer.add_child(btn)
	_btn_overlay_focus = btn

	return fond


# ── Paramètres ────────────────────────────────────────────────────

func _construire_parametres() -> Control:
	var f    = get_viewport().get_visible_rect().size.y / 1080.0
	var base = _creer_panneau_overlay(700, f)
	var fond   : Control          = base[0]
	var outer  : VBoxContainer    = base[1]
	var vbox   : VBoxContainer    = base[2]
	var scroll : ScrollContainer  = base[3]

	outer.add_child(_lbl("PARAMÈTRES", int(72 * f), C_OR, 10))
	outer.add_child(_lbl("Régle l'audio et la sensibilité de la caméra",
		int(22 * f), Color(0.75, 0.75, 0.92, 1.0), 3))
	outer.add_child(_sep(f))
	outer.add_child(scroll)

	# Volume
	vbox.add_child(_entete("Volume", f))
	var init_vol = _db_to_pct(AudioServer.get_bus_volume_db(0))
	var row_v    = _creer_row_slider(0.0, 100.0, 1.0, init_vol, f)
	var sl_v : HSlider = row_v[0]
	var lb_v : Label   = row_v[1]
	lb_v.text = str(int(init_vol)) + "%"
	sl_v.value_changed.connect(func(v: float) -> void:
		lb_v.text = str(int(v)) + "%"
		AudioServer.set_bus_volume_db(0, linear_to_db(max(v / 100.0, 0.001)))
	)
	vbox.add_child(row_v[2])
	vbox.add_child(_sep(f))

	# Sensibilité souris
	vbox.add_child(_entete("Sensibilité souris", f))
	var init_sens = BestScore.get_sensitivity()
	var row_s     = _creer_row_slider(1.0, 10.0, 0.5, init_sens, f)
	var sl_s : HSlider = row_s[0]
	var lb_s : Label   = row_s[1]
	lb_s.text = _fmt_sens(init_sens)
	sl_s.value_changed.connect(func(v: float) -> void:
		lb_s.text = _fmt_sens(v)
		BestScore.update_sensitivity(v)
	)
	vbox.add_child(row_s[2])

	outer.add_child(_sep(f))
	var btn = _btn("FERMER", f, false)
	btn.pressed.connect(_fermer_sous_panel)
	outer.add_child(btn)
	_btn_overlay_focus = btn

	return fond


# ── Crédits ───────────────────────────────────────────────────────

func _construire_credits() -> Control:
	var f    = get_viewport().get_visible_rect().size.y / 1080.0
	var base = _creer_panneau_overlay(840, f)
	var fond   : Control         = base[0]
	var outer  : VBoxContainer   = base[1]
	var vbox   : VBoxContainer   = base[2]
	var scroll : ScrollContainer = base[3]

	outer.add_child(_lbl("CRÉDITS", int(72 * f), C_OR, 10))
	outer.add_child(_sep(f))
	outer.add_child(scroll)

	vbox.add_child(_entete("Développement & Modélisation 3D", f))
	vbox.add_child(_corps("PEREZ Alexandre-Philippe",
		f, Color(1.0, 1.0, 1.0, 1.0), int(34 * f)))
	vbox.add_child(_corps("B2  —  My Digital School", f))
	vbox.add_child(_corps(
		"Modèles 3D réalisés sous Blender : Player, Client, Fusil\n" +
		"Contribution au code du jeu", f))
	vbox.add_child(_sep(f))

	vbox.add_child(_entete("Assets 3D", f))
	vbox.add_child(_corps(
		"Kay Lousberg — Restaurant Bits\n" +
		"kaylousberg.itch.io/restaurant-bits", f))
	vbox.add_child(_sep(f))

	vbox.add_child(_entete("Audio", f))
	vbox.add_child(_corps(
		"SFX — Libres de droits\n" +
		"Musiques — Générées via Suno", f))

	outer.add_child(_sep(f))
	var btn = _btn("FERMER", f, false)
	btn.pressed.connect(_fermer_sous_panel)
	outer.add_child(btn)
	_btn_overlay_focus = btn

	return fond


# ── Helpers UI ────────────────────────────────────────────────────

func _entete(texte: String, f: float) -> Label:
	return _lbl(texte, int(28 * f), C_OR2, 4, false)

func _corps(texte: String, f: float,
		couleur: Color = Color(0.88, 0.88, 0.88, 1.0),
		taille: int = 0) -> Label:
	var sz = taille if taille > 0 else int(22 * f)
	var l  = _lbl(texte, sz, couleur, 3, false)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _lbl(texte: String, taille: int, couleur: Color, outline: int,
		centre: bool = true) -> Label:
	var l = Label.new()
	l.text = texte
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centre else HORIZONTAL_ALIGNMENT_LEFT
	var s = LabelSettings.new()
	s.font          = FONT
	s.font_size     = taille
	s.font_color    = couleur
	s.outline_size  = outline
	s.outline_color = Color(0, 0, 0, 1)
	l.label_settings = s
	return l

func _sep(f: float) -> HSeparator:
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(0, int(4 * f))
	var sty = StyleBoxFlat.new()
	sty.bg_color           = Color(C_OR.r, C_OR.g, C_OR.b, 0.28)
	sty.content_margin_top = 3
	sep.add_theme_stylebox_override("separator", sty)
	return sep

func _btn(texte: String, f: float, primaire: bool) -> Button:
	var btn = Button.new()
	btn.text                = texte
	btn.custom_minimum_size = Vector2(int(290 * f), int(74 * f) if primaire else int(58 * f))
	btn.alignment           = HORIZONTAL_ALIGNMENT_CENTER
	btn.focus_mode          = Control.FOCUS_ALL
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", int(44 * f) if primaire else int(34 * f))
	btn.add_theme_color_override("font_color",         Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_hover_color",   Color(1, 1, 0.6, 1))
	btn.add_theme_color_override("font_focus_color",   Color(1, 1, 0.5, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 0.85, 0.2, 1))

	var bg_n = Color(0.22, 0.10, 0.0, 1.0) if primaire else C_BTN_N
	var bg_h = Color(0.40, 0.20, 0.0, 1.0) if primaire else C_BTN_H

	var sn = StyleBoxFlat.new()
	sn.bg_color                   = bg_n
	sn.corner_radius_top_left     = 14
	sn.corner_radius_top_right    = 14
	sn.corner_radius_bottom_left  = 14
	sn.corner_radius_bottom_right = 14
	sn.border_color               = C_OR
	sn.border_width_left          = 3
	sn.border_width_right         = 3
	sn.border_width_top           = 3
	sn.border_width_bottom        = 3
	btn.add_theme_stylebox_override("normal", sn)

	var sh = sn.duplicate() as StyleBoxFlat
	sh.bg_color = bg_h
	btn.add_theme_stylebox_override("hover", sh)

	var sf = sn.duplicate() as StyleBoxFlat
	sf.bg_color     = bg_h
	sf.border_color = C_OR2
	sf.border_width_left   = 5
	sf.border_width_right  = 5
	sf.border_width_top    = 5
	sf.border_width_bottom = 5
	btn.add_theme_stylebox_override("focus", sf)

	var sp = sn.duplicate() as StyleBoxFlat
	sp.bg_color = bg_h.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", sp)

	return btn

func _creer_row_slider(min_v: float, max_v: float, step: float, init: float, f: float) -> Array:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(16 * f))

	var slider = HSlider.new()
	slider.min_value             = min_v
	slider.max_value             = max_v
	slider.step                  = step
	slider.value                 = init
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size   = Vector2(0, int(40 * f))

	var bg = StyleBoxFlat.new()
	bg.bg_color                   = Color(0.18, 0.18, 0.38, 1.0)
	bg.corner_radius_top_left     = 8
	bg.corner_radius_top_right    = 8
	bg.corner_radius_bottom_left  = 8
	bg.corner_radius_bottom_right = 8
	bg.content_margin_top         = int(8 * f)
	bg.content_margin_bottom      = int(8 * f)
	slider.add_theme_stylebox_override("slider", bg)

	var fill = StyleBoxFlat.new()
	fill.bg_color                   = C_OR
	fill.corner_radius_top_left     = 8
	fill.corner_radius_top_right    = 8
	fill.corner_radius_bottom_left  = 8
	fill.corner_radius_bottom_right = 8
	fill.content_margin_top         = int(8 * f)
	fill.content_margin_bottom      = int(8 * f)
	slider.add_theme_stylebox_override("grabber_area",           fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.add_theme_icon_override("grabber",           _rond(int(22 * f), Color(1, 1, 1)))
	slider.add_theme_icon_override("grabber_highlight",  _rond(int(26 * f), Color(1.0, 0.9, 0.4)))
	slider.add_theme_icon_override("grabber_disabled",   _rond(int(22 * f), Color(0.5, 0.5, 0.5)))
	hbox.add_child(slider)

	var lbl = Label.new()
	lbl.custom_minimum_size  = Vector2(int(72 * f), 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var sv = LabelSettings.new()
	sv.font          = FONT
	sv.font_size     = int(30 * f)
	sv.font_color    = Color(1.0, 1.0, 1.0, 0.95)
	sv.outline_size  = 4
	sv.outline_color = Color(0, 0, 0, 1)
	lbl.label_settings = sv
	hbox.add_child(lbl)

	return [slider, lbl, hbox]

func _rond(taille: int, couleur: Color) -> ImageTexture:
	var img    = Image.create(taille, taille, false, Image.FORMAT_RGBA8)
	var centre = Vector2(taille * 0.5, taille * 0.5)
	var r      = taille * 0.5 - 1.0
	for x in range(taille):
		for y in range(taille):
			if Vector2(x, y).distance_to(centre) <= r:
				img.set_pixel(x, y, couleur)
	return ImageTexture.create_from_image(img)

func _db_to_pct(db: float) -> float:
	return clamp(db_to_linear(db) * 100.0, 0.0, 100.0)

func _fmt_sens(val: float) -> String:
	return str(snapped(val, 0.5))

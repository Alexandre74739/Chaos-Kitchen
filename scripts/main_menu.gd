extends Node3D

const FONT       = preload("res://assets/fonts/MatchaCih.ttf")
const MAIN_SCENE = preload("res://main.tscn")

const C_BG    := Color(0.05, 0.05, 0.18, 0.96)
const C_OR    := Color(1.0,  0.72, 0.0,  1.0)
const C_OR2   := Color(1.0,  0.88, 0.45, 1.0)
const C_JAUNE := Color(1.0,  1.0,  0.2,  1.0)
const C_BTN_N := Color(0.15, 0.15, 0.40, 1.0)
const C_BTN_H := Color(0.28, 0.28, 0.65, 1.0)

var _label_best        : Label           = null
var _sous_panel        : Control         = null
var _btn_jouer         : Button          = null
var _btn_overlay_focus : Control         = null
var _scroll_actif      : ScrollContainer = null
var _panneau_gauche    : Control         = null
var _cam               : Camera3D        = null
var _cam_end_transform : Transform3D

func _process(delta: float) -> void:
	if _scroll_actif == null or not _scroll_actif.is_inside_tree():
		return
	if get_viewport().gui_get_focus_owner() is HSlider:
		return
	var axis : float = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if abs(axis) < 0.2:
		axis = 0.0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
		axis = 1.0
	elif Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
		axis = -1.0
	if axis != 0.0:
		_scroll_actif.scroll_vertical += int(axis * 420.0 * delta)


func _ready() -> void:
	_setup_backdrop()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_setup_camera()
	_setup_ui()
	_jouer_intro()

func _jouer_intro() -> void:
	AudioManager.jouer_musique("intro")
	if not AudioManager.musique_player.finished.is_connected(_jouer_intro):
		AudioManager.musique_player.finished.connect(_jouer_intro)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			(focused as Button).emit_signal("pressed")
			get_viewport().set_input_as_handled()


# ── BACKDROP : scène de jeu sans logique ──────────────────────────

func _setup_backdrop() -> void:
	var world = MAIN_SCENE.instantiate()
	world.set_script(null)
	var player_node = world.get_node_or_null("Player")
	if player_node:
		player_node.set_script(null)
	add_child(world)

	var anim = world.get_node_or_null("Player/LeanPivot/AnimPlayerGodot")
	if anim:
		anim.play("idle_organic")


# ── CAMÉRA MENU ───────────────────────────────────────────────────
# Player en (7.51, 1.54, -4.57) dans main.tscn, face à -Z (cuisine).
# Vue 3/4 depuis la GAUCHE (-X) et légèrement devant (-Z) :
#   player apparaît sur la DROITE du cadre → panel UI à droite.

func _setup_camera() -> void:
	# Désactive la caméra du joueur si elle est devenue active
	for child in get_children():
		var pc = child.get_node_or_null("Player/CameraRoot/SpringArm3D/Camera3D")
		if pc:
			pc.current = false
			break

	# Vue de face, proche : caméra en Z négatif (devant le player qui regarde -Z),
	# légèrement décalée en X pour éviter les murs de cuisine.
	_cam          = Camera3D.new()
	_cam.fov      = 50.0
	_cam.position = Vector3(8, 2.5, -8.0)
	add_child(_cam)
	_cam.look_at(Vector3(7.51, 1.8, -4.57), Vector3.UP)
	_cam.current = true

	# Pré-calcul de la transform de fin (vue derrière/dessus le joueur)
	var helper = Camera3D.new()
	helper.position = Vector3(7.51, 4.5, 0.5)
	add_child(helper)
	helper.look_at(Vector3(7.51, 1.5, -4.57), Vector3.UP)
	_cam_end_transform = helper.global_transform
	helper.queue_free()


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

	if _btn_jouer:
		_btn_jouer.call_deferred("grab_focus")


func _creer_panneau_gauche() -> Control:
	var f = get_viewport().get_visible_rect().size.y / 1080.0

	var panel = PanelContainer.new()
	_panneau_gauche     = panel
	panel.anchor_left   = 0.67
	panel.anchor_right  = 1.0
	panel.anchor_bottom = 1.0

	var sty = StyleBoxFlat.new()
	sty.bg_color          = C_BG
	sty.border_color      = C_OR
	sty.border_width_left = 5
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

	var hint = _lbl("Manette : D-Pad naviguer  ·  A/Croix sélectionner",
		int(18 * f), Color(0.75, 0.75, 0.60, 0.75), 3)
	vbox.add_child(hint)

	return panel


# ── Actions ───────────────────────────────────────────────────────

func _on_jouer() -> void:
	if _btn_jouer:
		_btn_jouer.disabled = true

	# Déconnecte la boucle de l'intro et démarre le fondu sortant
	if AudioManager.musique_player.finished.is_connected(_jouer_intro):
		AudioManager.musique_player.finished.disconnect(_jouer_intro)

	var tween = create_tween()
	tween.set_parallel(true)

	# Fondu sortant du panneau
	if _panneau_gauche:
		tween.tween_property(_panneau_gauche, "modulate:a", 0.0, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Fondu sortant de l'intro sur toute la durée de l'animation caméra
	tween.tween_property(AudioManager.musique_player, "volume_db", -60.0, 3.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Animation FOV
	tween.tween_property(_cam, "fov", 52.0, 3.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Animation de la transform caméra
	var t0 := _cam.global_transform
	var t1 := _cam_end_transform
	tween.tween_method(
		func(v: float) -> void:
			_cam.global_transform = t0.interpolate_with(t1, v),
		0.0, 1.0, 3.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	# Fondu au noir pour masquer le saut de caméra au changement de scène
	var fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	var rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(rect)
	var fade = create_tween()
	fade.tween_property(rect, "color:a", 1.0, 0.35)
	await fade.finished

	AudioManager.arreter_musique()
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
	_scroll_actif      = null
	_sous_panel.visible = false
	for c in _sous_panel.get_children():
		c.queue_free()
	if _btn_jouer:
		_btn_jouer.call_deferred("grab_focus")


# ── Fabrique panneau centré avec scroll ───────────────────────────

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
	var fond       : Control         = base[0]
	var outer      : VBoxContainer   = base[1]
	var vbox       : VBoxContainer   = base[2]
	var scroll     : ScrollContainer = base[3]

	outer.add_child(_lbl("RÈGLES", int(72 * f), C_OR, 10))
	outer.add_child(_sep(f))
	outer.add_child(scroll)

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

	outer.add_child(_sep(f))
	var btn = _btn("FERMER", f, false)
	btn.pressed.connect(_fermer_sous_panel)
	outer.add_child(btn)
	_btn_overlay_focus = btn
	_scroll_actif      = base[3]

	return fond


# ── Paramètres ────────────────────────────────────────────────────

func _construire_parametres() -> Control:
	var f    = get_viewport().get_visible_rect().size.y / 1080.0
	var base = _creer_panneau_overlay(700, f)
	var fond   : Control         = base[0]
	var outer  : VBoxContainer   = base[1]
	var vbox   : VBoxContainer   = base[2]
	var scroll : ScrollContainer = base[3]

	outer.add_child(_lbl("PARAMÈTRES", int(72 * f), C_OR, 10))
	outer.add_child(_lbl("Régle l'audio et la sensibilité de la caméra",
		int(22 * f), Color(0.75, 0.75, 0.92, 1.0), 3))
	outer.add_child(_sep(f))
	outer.add_child(scroll)

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
	_btn_overlay_focus = sl_v
	_scroll_actif      = base[3]

	fond.ready.connect(func():
		sl_v.focus_neighbor_bottom = sl_v.get_path_to(sl_s)
		sl_v.focus_neighbor_top    = sl_v.get_path_to(btn)
		sl_s.focus_neighbor_bottom = sl_s.get_path_to(btn)
		sl_s.focus_neighbor_top    = sl_s.get_path_to(sl_v)
		btn.focus_neighbor_top     = btn.get_path_to(sl_s)
		btn.focus_neighbor_bottom  = btn.get_path_to(sl_v)
	)

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
	_scroll_actif      = base[3]

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
	slider.focus_mode            = Control.FOCUS_ALL

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
	slider.add_theme_icon_override("grabber",          _rond(int(22 * f), Color(1, 1, 1)))
	slider.add_theme_icon_override("grabber_highlight", _rond(int(26 * f), Color(1.0, 0.9, 0.4)))
	slider.add_theme_icon_override("grabber_disabled",  _rond(int(22 * f), Color(0.5, 0.5, 0.5)))
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

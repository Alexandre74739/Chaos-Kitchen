extends CanvasLayer

const FONT = preload("res://assets/fonts/MatchaCih.ttf")

var _en_pause            := false
var _slider_sensibilite  : HSlider = null
var _lbl_val_sens        : Label   = null
var _slider_volume       : HSlider = null
var _lbl_val_volume      : Label   = null
var _btn_reprendre       : Button  = null

func _ready() -> void:
	layer        = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible      = false
	_construire_ui()

# ─────────────────────────────────────────────────────────────
func _construire_ui() -> void:
	var f = get_viewport().get_visible_rect().size.y / 1080.0

	var fond = ColorRect.new()
	fond.color = Color(0, 0, 0, 0.65)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	var centre = CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	# ── Panneau principal ─────────────────────────────────
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(int(740 * f), 0)
	var style = StyleBoxFlat.new()
	style.bg_color                   = Color(0.07, 0.07, 0.22, 0.97)
	style.corner_radius_top_left     = 28
	style.corner_radius_top_right    = 28
	style.corner_radius_bottom_left  = 28
	style.corner_radius_bottom_right = 28
	style.border_color               = Color(1.0, 0.72, 0.0, 1.0)
	style.border_width_left          = 5
	style.border_width_right         = 5
	style.border_width_top           = 5
	style.border_width_bottom        = 5
	style.content_margin_left        = int(64 * f)
	style.content_margin_right       = int(64 * f)
	style.content_margin_top         = int(52 * f)
	style.content_margin_bottom      = int(60 * f)
	panel.add_theme_stylebox_override("panel", style)
	centre.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", int(16 * f))
	panel.add_child(vbox)

	# ── Titre ─────────────────────────────────────────────
	var titre = Label.new()
	titre.text                 = "PAUSE"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var st = LabelSettings.new()
	st.font          = FONT
	st.font_size     = int(80 * f)
	st.font_color    = Color(1.0, 0.72, 0.0, 1.0)
	st.outline_size  = 10
	st.outline_color = Color(0, 0, 0, 1)
	titre.label_settings = st
	vbox.add_child(titre)

	# ── Sous-titre ────────────────────────────────────────
	var sous = Label.new()
	sous.text                 = "Prends une pause, chef !"
	sous.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ss = LabelSettings.new()
	ss.font          = FONT
	ss.font_size     = int(32 * f)
	ss.font_color    = Color(0.72, 0.72, 1.0, 0.85)
	ss.outline_size  = 4
	ss.outline_color = Color(0, 0, 0, 1)
	sous.label_settings = ss
	vbox.add_child(sous)

	# ── Hint manette ──────────────────────────────────────
	var hint = Label.new()
	hint.text                 = "Manette : Start pour reprendre  ·  B / Rond pour quitter"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sh = LabelSettings.new()
	sh.font          = FONT
	sh.font_size     = int(22 * f)
	sh.font_color    = Color(0.85, 0.85, 0.65, 0.80)
	sh.outline_size  = 3
	sh.outline_color = Color(0, 0, 0, 1)
	hint.label_settings = sh
	vbox.add_child(hint)

	vbox.add_child(_sep(f))

	# ── Sensibilité souris ────────────────────────────────
	vbox.add_child(_lbl_section("Sensibilite souris", f))
	var _init_sens := 3.0
	var _bs_init = get_node_or_null("/root/BestScore")
	if _bs_init:
		_init_sens = _bs_init.get_sensitivity()
	var row_s = _creer_row_slider(1.0, 10.0, 0.5, _init_sens, f)
	_slider_sensibilite = row_s[0]
	_lbl_val_sens       = row_s[1]
	_lbl_val_sens.text  = _fmt_sens(_slider_sensibilite.value)
	_slider_sensibilite.value_changed.connect(func(v): _on_sensibilite(v))
	vbox.add_child(row_s[2])

	# ── Volume ────────────────────────────────────────────
	vbox.add_child(_lbl_section("Volume", f))
	var init_vol = _db_to_pct(AudioServer.get_bus_volume_db(0))
	var row_v    = _creer_row_slider(0.0, 100.0, 1.0, init_vol, f)
	_slider_volume  = row_v[0]
	_lbl_val_volume = row_v[1]
	_lbl_val_volume.text = _fmt_vol(_slider_volume.value)
	_slider_volume.value_changed.connect(func(v): _on_volume(v))
	vbox.add_child(row_v[2])

	vbox.add_child(_sep(f))

	# ── Boutons ───────────────────────────────────────────
	_btn_reprendre = _creer_bouton("Reprendre", f)
	_btn_reprendre.focus_mode = Control.FOCUS_ALL
	_btn_reprendre.pressed.connect(_reprendre)
	vbox.add_child(_btn_reprendre)

	var btn_q = _creer_bouton("Quitter", f)
	btn_q.pressed.connect(_quitter)
	vbox.add_child(btn_q)

# ── Ligne slider + valeur ─────────────────────────────────────
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

	# Piste (fond gris)
	var bg = StyleBoxFlat.new()
	bg.bg_color                   = Color(0.18, 0.18, 0.38, 1.0)
	bg.corner_radius_top_left     = 8
	bg.corner_radius_top_right    = 8
	bg.corner_radius_bottom_left  = 8
	bg.corner_radius_bottom_right = 8
	bg.content_margin_top         = int(8 * f)
	bg.content_margin_bottom      = int(8 * f)
	slider.add_theme_stylebox_override("slider", bg)

	# Zone remplie (or)
	var fill = StyleBoxFlat.new()
	fill.bg_color                   = Color(1.0, 0.72, 0.0, 1.0)
	fill.corner_radius_top_left     = 8
	fill.corner_radius_top_right    = 8
	fill.corner_radius_bottom_left  = 8
	fill.corner_radius_bottom_right = 8
	fill.content_margin_top         = int(8 * f)
	fill.content_margin_bottom      = int(8 * f)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)

	# Poignée ronde blanche
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

# ── Icône ronde pour la poignée ───────────────────────────────
func _rond(taille: int, couleur: Color) -> ImageTexture:
	var img    = Image.create(taille, taille, false, Image.FORMAT_RGBA8)
	var centre = Vector2(taille * 0.5, taille * 0.5)
	var r      = taille * 0.5 - 1.0
	for x in range(taille):
		for y in range(taille):
			if Vector2(x, y).distance_to(centre) <= r:
				img.set_pixel(x, y, couleur)
	return ImageTexture.create_from_image(img)

# ── Widgets utilitaires ───────────────────────────────────────
func _lbl_section(texte: String, f: float) -> Label:
	var lbl = Label.new()
	lbl.text                 = texte
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var s = LabelSettings.new()
	s.font          = FONT
	s.font_size     = int(32 * f)
	s.font_color    = Color(1.0, 0.88, 0.45, 1.0)
	s.outline_size  = 4
	s.outline_color = Color(0, 0, 0, 1)
	lbl.label_settings = s
	return lbl

func _sep(f: float) -> HSeparator:
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(0, int(6 * f))
	var sty = StyleBoxFlat.new()
	sty.bg_color           = Color(1.0, 0.72, 0.0, 0.25)
	sty.content_margin_top = 3
	sep.add_theme_stylebox_override("separator", sty)
	return sep

func _creer_bouton(texte: String, f: float) -> Button:
	var btn = Button.new()
	btn.text                = texte
	btn.custom_minimum_size = Vector2(int(320 * f), int(68 * f))
	btn.alignment           = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", int(40 * f))

	var sn = StyleBoxFlat.new()
	sn.bg_color                   = Color(0.15, 0.15, 0.40, 1.0)
	sn.corner_radius_top_left     = 14
	sn.corner_radius_top_right    = 14
	sn.corner_radius_bottom_left  = 14
	sn.corner_radius_bottom_right = 14
	btn.add_theme_stylebox_override("normal", sn)

	var sh = sn.duplicate() as StyleBoxFlat
	sh.bg_color = Color(0.28, 0.28, 0.65, 1.0)
	btn.add_theme_stylebox_override("hover", sh)

	return btn

# ── Callbacks sliders ─────────────────────────────────────────
func _on_sensibilite(val: float) -> void:
	_lbl_val_sens.text = _fmt_sens(val)
	var bs = get_node_or_null("/root/BestScore")
	if bs:
		bs.update_sensitivity(val)
	var player = _get_player()
	if player and "mouse_sensitivity" in player:
		player.mouse_sensitivity = val / 1000.0

func _on_volume(val: float) -> void:
	_lbl_val_volume.text = _fmt_vol(val)
	AudioServer.set_bus_volume_db(0, linear_to_db(max(val / 100.0, 0.001)))

# ── Formatage ─────────────────────────────────────────────────
func _fmt_sens(val: float) -> String:
	return str(snapped(val, 0.5))

func _fmt_vol(val: float) -> String:
	return str(int(val)) + "%"

func _db_to_pct(db: float) -> float:
	return clamp(db_to_linear(db) * 100.0, 0.0, 100.0)

# ── Accès joueur ──────────────────────────────────────────────
func _get_player() -> Node:
	return get_parent().find_child("Player", true, false)

# ── Entrée clavier ────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _en_pause:
			_reprendre()
		else:
			afficher()
		get_viewport().set_input_as_handled()

# ── Contrôle externe ──────────────────────────────────────────
func afficher() -> void:
	_en_pause = true
	visible   = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _slider_volume:
		_slider_volume.value = _db_to_pct(AudioServer.get_bus_volume_db(0))
	var player = _get_player()
	if player and "mouse_sensitivity" in player and _slider_sensibilite:
		_slider_sensibilite.value = player.mouse_sensitivity * 1000.0
	if _btn_reprendre:
		_btn_reprendre.grab_focus()

func _reprendre() -> void:
	_en_pause = false
	visible   = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _quitter() -> void:
	get_tree().paused = false
	get_tree().quit()

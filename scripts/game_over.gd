extends CanvasLayer

const FONT = preload("res://assets/fonts/MatchaCih.ttf")

var _label_score  : Label  = null
var _label_raison : Label  = null
var _btn_rejouer  : Button = null

func _ready() -> void:
	layer        = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible      = false
	_construire_ui()

func afficher(score_final: int, raison: String = "") -> void:
	if _label_score:
		_label_score.text = "Score final : " + str(score_final)
	if _label_raison:
		_label_raison.text = raison
		_label_raison.visible = raison != ""
	var bs = get_node_or_null("/root/BestScore")
	if bs:
		bs.update(score_final)
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _btn_rejouer:
		_btn_rejouer.grab_focus()

func _construire_ui() -> void:
	var f = get_viewport().get_visible_rect().size.y / 1080.0

	var fond = ColorRect.new()
	fond.color = Color(0, 0, 0, 0.80)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	var centre = CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	# ── Panneau principal ─────────────────────────────────
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(int(580 * f), 0)
	var sty = StyleBoxFlat.new()
	sty.bg_color                   = Color(0.10, 0.03, 0.03, 0.97)
	sty.corner_radius_top_left     = 26
	sty.corner_radius_top_right    = 26
	sty.corner_radius_bottom_left  = 26
	sty.corner_radius_bottom_right = 26
	sty.border_color               = Color(1.0, 0.22, 0.20, 1.0)
	sty.border_width_left          = 5
	sty.border_width_right         = 5
	sty.border_width_top           = 5
	sty.border_width_bottom        = 5
	sty.content_margin_left        = int(64 * f)
	sty.content_margin_right       = int(64 * f)
	sty.content_margin_top         = int(52 * f)
	sty.content_margin_bottom      = int(56 * f)
	panel.add_theme_stylebox_override("panel", sty)
	centre.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", int(20 * f))
	panel.add_child(vbox)

	# ── Titre ─────────────────────────────────────────────
	var titre = Label.new()
	titre.text                 = "GAME OVER"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var st = LabelSettings.new()
	st.font          = FONT
	st.font_size     = int(88 * f)
	st.font_color    = Color(1.0, 0.18, 0.18, 1.0)
	st.outline_size  = 11
	st.outline_color = Color(0, 0, 0, 1)
	titre.label_settings = st
	vbox.add_child(titre)

	# ── Séparateur ────────────────────────────────────────
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(0, int(4 * f))
	var sep_sty = StyleBoxFlat.new()
	sep_sty.bg_color           = Color(1.0, 0.22, 0.20, 0.35)
	sep_sty.content_margin_top = 3
	sep.add_theme_stylebox_override("separator", sep_sty)
	vbox.add_child(sep)

	# ── Score final ───────────────────────────────────────
	var lbl_titre_score = Label.new()
	lbl_titre_score.text                 = "SCORE FINAL"
	lbl_titre_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var stt = LabelSettings.new()
	stt.font          = FONT
	stt.font_size     = int(28 * f)
	stt.font_color    = Color(1.0, 0.72, 0.0, 1.0)
	stt.outline_size  = 4
	stt.outline_color = Color(0, 0, 0, 1)
	lbl_titre_score.label_settings = stt
	vbox.add_child(lbl_titre_score)

	_label_score = Label.new()
	_label_score.text                 = "0"
	_label_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ss = LabelSettings.new()
	ss.font          = FONT
	ss.font_size     = int(72 * f)
	ss.font_color    = Color(1.0, 0.85, 0.2, 1.0)
	ss.outline_size  = 9
	ss.outline_color = Color(0, 0, 0, 1)
	_label_score.label_settings = ss
	vbox.add_child(_label_score)

	# ── Raison du Game Over ───────────────────────────────
	_label_raison = Label.new()
	_label_raison.text                 = ""
	_label_raison.visible              = false
	_label_raison.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_raison.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_label_raison.custom_minimum_size  = Vector2(int(460 * f), 0)
	var sr = LabelSettings.new()
	sr.font          = FONT
	sr.font_size     = int(26 * f)
	sr.font_color    = Color(1.0, 0.55, 0.55, 1.0)
	sr.outline_size  = 4
	sr.outline_color = Color(0, 0, 0, 1)
	_label_raison.label_settings = sr
	vbox.add_child(_label_raison)

	# ── Hint manette ──────────────────────────────────────
	var hint = Label.new()
	hint.text                 = "Manette : A / Croix pour rejouer"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hint_sty = LabelSettings.new()
	hint_sty.font          = FONT
	hint_sty.font_size     = int(22 * f)
	hint_sty.font_color    = Color(0.85, 0.85, 0.65, 0.75)
	hint_sty.outline_size  = 3
	hint_sty.outline_color = Color(0, 0, 0, 1)
	hint.label_settings = hint_sty
	vbox.add_child(hint)

	# ── Bouton Rejouer ────────────────────────────────────
	_btn_rejouer = Button.new()
	_btn_rejouer.text                = "REJOUER"
	_btn_rejouer.custom_minimum_size = Vector2(int(260 * f), int(68 * f))
	_btn_rejouer.alignment           = HORIZONTAL_ALIGNMENT_CENTER
	_btn_rejouer.focus_mode          = Control.FOCUS_ALL
	_btn_rejouer.add_theme_font_override("font", FONT)
	_btn_rejouer.add_theme_font_size_override("font_size", int(40 * f))
	_btn_rejouer.add_theme_color_override("font_color",         Color(1, 1, 1, 1))
	_btn_rejouer.add_theme_color_override("font_hover_color",   Color(1, 1, 0.5, 1))
	_btn_rejouer.add_theme_color_override("font_focus_color",   Color(1, 1, 0.5, 1))
	_btn_rejouer.add_theme_color_override("font_pressed_color", Color(1, 0.8, 0.2, 1))

	var btn_n = StyleBoxFlat.new()
	btn_n.bg_color                   = Color(0.15, 0.15, 0.40, 1.0)
	btn_n.corner_radius_top_left     = 14
	btn_n.corner_radius_top_right    = 14
	btn_n.corner_radius_bottom_left  = 14
	btn_n.corner_radius_bottom_right = 14
	btn_n.border_color               = Color(1.0, 0.72, 0.0, 1.0)
	btn_n.border_width_left          = 3
	btn_n.border_width_right         = 3
	btn_n.border_width_top           = 3
	btn_n.border_width_bottom        = 3
	_btn_rejouer.add_theme_stylebox_override("normal", btn_n)

	var btn_h = btn_n.duplicate() as StyleBoxFlat
	btn_h.bg_color     = Color(0.28, 0.28, 0.65, 1.0)
	btn_h.border_color = Color(1.0, 0.90, 0.30, 1.0)
	_btn_rejouer.add_theme_stylebox_override("hover", btn_h)

	var btn_f = btn_h.duplicate() as StyleBoxFlat
	btn_f.bg_color = Color(0.28, 0.28, 0.65, 1.0)
	_btn_rejouer.add_theme_stylebox_override("focus", btn_f)

	var btn_p = btn_n.duplicate() as StyleBoxFlat
	btn_p.bg_color = Color(0.22, 0.22, 0.55, 1.0)
	_btn_rejouer.add_theme_stylebox_override("pressed", btn_p)

	_btn_rejouer.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	vbox.add_child(_btn_rejouer)

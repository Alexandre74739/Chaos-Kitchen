extends CanvasLayer

const FONT = preload("res://assets/fonts/MatchaCih.ttf")

var _label_score : Label = null

func _ready() -> void:
	layer        = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible      = false
	_construire_ui()

func afficher(score_final: int) -> void:
	if _label_score:
		_label_score.text = "Score final : " + str(score_final)
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _construire_ui() -> void:
	var facteur = get_viewport().get_visible_rect().size.y / 1080.0

	var fond = ColorRect.new()
	fond.color = Color(0, 0, 0, 0.80)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	var centre = CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color                   = Color(0.12, 0.04, 0.04, 0.95)
	style.corner_radius_top_left     = 24
	style.corner_radius_top_right    = 24
	style.corner_radius_bottom_left  = 24
	style.corner_radius_bottom_right = 24
	style.border_color               = Color(1.0, 0.224, 0.208, 1.0)
	style.border_width_left          = 4
	style.border_width_right         = 4
	style.border_width_top           = 4
	style.border_width_bottom        = 4
	style.content_margin_left        = int(64 * facteur)
	style.content_margin_right       = int(64 * facteur)
	style.content_margin_top         = int(52 * facteur)
	style.content_margin_bottom      = int(52 * facteur)
	panel.add_theme_stylebox_override("panel", style)
	centre.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", int(26 * facteur))
	panel.add_child(vbox)

	var titre = Label.new()
	titre.text                 = "GAME OVER"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var st = LabelSettings.new()
	st.font          = FONT
	st.font_size     = int(88 * facteur)
	st.font_color    = Color(1.0, 0.18, 0.18, 1.0)
	st.outline_size  = 11
	st.outline_color = Color(0, 0, 0, 1)
	titre.label_settings = st
	vbox.add_child(titre)

	_label_score = Label.new()
	_label_score.text                 = "Score final : 0"
	_label_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ss = LabelSettings.new()
	ss.font          = FONT
	ss.font_size     = int(46 * facteur)
	ss.font_color    = Color(1.0, 0.85, 0.2, 1.0)
	ss.outline_size  = 7
	ss.outline_color = Color(0, 0, 0, 1)
	_label_score.label_settings = ss
	vbox.add_child(_label_score)

	var btn = Button.new()
	btn.text                = "Rejouer"
	btn.custom_minimum_size = Vector2(int(260 * facteur), int(64 * facteur))
	btn.alignment           = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", int(38 * facteur))

	var sn = StyleBoxFlat.new()
	sn.bg_color                   = Color(0.15, 0.15, 0.40, 1.0)
	sn.corner_radius_top_left     = 12
	sn.corner_radius_top_right    = 12
	sn.corner_radius_bottom_left  = 12
	sn.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", sn)

	var sh = sn.duplicate() as StyleBoxFlat
	sh.bg_color = Color(0.25, 0.25, 0.60, 1.0)
	btn.add_theme_stylebox_override("hover", sh)

	btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	vbox.add_child(btn)

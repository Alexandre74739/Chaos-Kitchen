extends CanvasLayer

const FONT = preload("res://assets/fonts/MatchaCih.ttf")

var _score        : int   = 0
var _tween_score  : Tween = null
var _label_score  : Label = null
var _panel        : PanelContainer = null

func _ready() -> void:
	layer = 20
	_construire_ui()

func _construire_ui() -> void:
	var vp_h       = get_viewport().get_visible_rect().size.y
	var facteur    = vp_h / 1080.0

	# ── Panneau arrondi style cartoon ─────────────────────
	_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color                   = Color(0.07, 0.07, 0.22, 0.82)
	style.corner_radius_top_left     = 20
	style.corner_radius_top_right    = 20
	style.corner_radius_bottom_left  = 20
	style.corner_radius_bottom_right = 20
	style.border_color               = Color(1.0, 0.72, 0.0, 1.0)
	style.border_width_left          = 4
	style.border_width_right         = 4
	style.border_width_top           = 4
	style.border_width_bottom        = 4
	style.content_margin_left        = 16
	style.content_margin_right       = 16
	style.content_margin_top         = 8
	style.content_margin_bottom      = 10
	_panel.add_theme_stylebox_override("panel", style)
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.offset_left = 24
	_panel.offset_top  = 24
	add_child(_panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	# ── Label "SCORE" ──────────────────────────────────────
	var label_titre = Label.new()
	label_titre.text                     = "SCORE"
	label_titre.horizontal_alignment     = HORIZONTAL_ALIGNMENT_CENTER
	var st = LabelSettings.new()
	st.font          = FONT
	st.font_size     = int(28 * facteur)
	st.font_color    = Color(1.0, 0.72, 0.0, 1.0)
	st.outline_size  = 5
	st.outline_color = Color(0.0, 0.0, 0.0, 1.0)
	label_titre.label_settings = st
	vbox.add_child(label_titre)

	# ── Label valeur du score ─────────────────────────────
	_label_score = Label.new()
	_label_score.text                 = "0"
	_label_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_score.custom_minimum_size  = Vector2(160 * facteur, 0)
	var ss = LabelSettings.new()
	ss.font          = FONT
	ss.font_size     = int(72 * facteur)
	ss.font_color    = Color(1.0, 1.0, 0.2, 1.0)
	ss.outline_size  = 9
	ss.outline_color = Color(0.0, 0.0, 0.0, 1.0)
	_label_score.label_settings = ss
	vbox.add_child(_label_score)

# ── Appelé par main.gd à chaque changement ────────────────────
func mettre_a_jour(nouveau_score: int, delta: int) -> void:
	var ancien = _score
	_score     = nouveau_score

	# Roulette : compte de l'ancien vers le nouveau
	if _tween_score:
		_tween_score.kill()
	_tween_score = create_tween()
	_tween_score.tween_method(_afficher_score, float(ancien), float(nouveau_score), 0.45)

	# Flash couleur sur le label
	var flash = Color(0.4, 1.0, 0.4) if delta > 0 else Color(1.0, 0.4, 0.4)
	var tw_flash = create_tween()
	tw_flash.tween_property(_label_score, "modulate", flash, 0.12)
	tw_flash.tween_property(_label_score, "modulate", Color(1, 1, 1), 0.18)

	_afficher_delta(delta)

func _afficher_score(val: float) -> void:
	_label_score.text = str(roundi(val))

func _afficher_delta(delta: int) -> void:
	var vp_h    = get_viewport().get_visible_rect().size.y
	var facteur = vp_h / 1080.0

	var lbl  = Label.new()
	lbl.text = ("+" if delta > 0 else "") + str(delta)
	lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	lbl.offset_left = 38
	lbl.offset_top  = int(150 * facteur)

	var sd = LabelSettings.new()
	sd.font          = FONT
	sd.font_size     = int(46 * facteur)
	sd.font_color    = Color(0.3, 1.0, 0.3) if delta > 0 else Color(1.0, 0.3, 0.3)
	sd.outline_size  = 6
	sd.outline_color = Color(0.0, 0.0, 0.0, 1.0)
	lbl.label_settings = sd
	add_child(lbl)

	var tw = create_tween()
	tw.tween_property(lbl, "offset_top", lbl.offset_top - int(80 * facteur), 1.0)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
	tw.tween_callback(lbl.queue_free)

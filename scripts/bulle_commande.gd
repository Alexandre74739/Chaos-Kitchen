extends Node3D

# Assets identiques à ceux que le joueur ramasse
const SCENES : Dictionary = {
	"salade"  : preload("res://assets/food_ingredient_lettuce.fbx"),
	"viande"  : preload("res://assets/food_ingredient_burger_cooked.fbx"),
	"fromage" : preload("res://assets/food_ingredient_cheese.fbx"),
	"tomate"  : preload("res://assets/food_ingredient_tomato.fbx"),
}

const PATIENCE_MAX  : float    = 45.0
const VP_SIZE       : Vector2i = Vector2i(380, 380)
const SPRITE_W      : float    = 0.90
const CAM_SIZE      : float    = 1.60
const GRID_X        : float    = 0.44
const GRID_Y        : float    = 0.55
const SHADER_BORDER : Shader   = preload("res://shaders/patience_border.gdshader")

# Échelle par ingrédient (ajuste selon la taille visuelle réelle du mesh)
const SCALES : Dictionary = {
	"salade"  : 0.55,
	"viande"  : 0.75,
	"fromage" : 0.52,
	"tomate"  : 0.70,
}

var _timer      : Timer          = null
var _border_mat : ShaderMaterial = null
var _camera     : Camera3D       = null
var _viewport   : SubViewport    = null

func setup(commande: Array, timer: Timer) -> void:
	_timer   = timer
	position = Vector3(0, 1.8, 0)
	_construire(commande)

func _construire(commande: Array) -> void:
	# Garde uniquement les milieux (pas les pains)
	var milieux : Array = commande.filter(func(n): return n != "pain_bas" and n != "pain_haut")
	var sprite_h : float = VP_SIZE.y * (SPRITE_W / float(VP_SIZE.x))

	# ═══════════════════════════════════════════════════
	# SubViewport : caméra + lumières + ingrédients
	# ═══════════════════════════════════════════════════
	_viewport = SubViewport.new()
	_viewport.size                      = VP_SIZE
	_viewport.transparent_bg            = true
	_viewport.own_world_3d              = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	# ── Caméra orthographique ─────────────────────────
	var cam        = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size       = CAM_SIZE
	cam.position   = Vector3(0.0, 0.0, 4.0)
	_viewport.add_child(cam)

	# ── Lumière principale ────────────────────────────
	var lumiere              = DirectionalLight3D.new()
	lumiere.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	lumiere.light_energy     = 2.0
	lumiere.shadow_enabled   = false
	_viewport.add_child(lumiere)

	# ── Fill light ────────────────────────────────────
	var fill              = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(15.0, -150.0, 0.0)
	fill.light_energy     = 0.7
	_viewport.add_child(fill)

	# ── Ambiance ─────────────────────────────────────
	var we  = WorldEnvironment.new()
	var env = Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color  = Color(1.0, 0.98, 0.95)
	env.ambient_light_energy = 0.6
	we.environment           = env
	_viewport.add_child(we)

	# ── Grille 2 colonnes max ─────────────────────────
	var nb       = milieux.size()
	var nb_rows  = ceili(nb / 2.0)
	for i in nb:
		var nom   = milieux[i]
		var scene = SCENES.get(nom)
		if scene == null:
			continue

		var row = i / 2
		var col = i % 2

		# Dernière rangée avec 1 seul élément → centré
		var nb_in_row = 2
		if row == nb_rows - 1 and nb % 2 == 1:
			nb_in_row = 1

		var x : float = 0.0 if nb_in_row == 1 else (col * 2 - 1) * GRID_X
		var y : float = (row - (nb_rows - 1) * 0.5) * GRID_Y

		var s    = SCALES.get(nom, 0.70)
		var node = scene.instantiate()
		node.scale            = Vector3(s, s, s)
		node.rotation_degrees = Vector3(-15.0, 22.0, 0.0)
		node.position         = Vector3(x, y, 0.0)
		_viewport.add_child(node)

	# ═══════════════════════════════════════════════════
	# Habillage dans la scène principale
	# ═══════════════════════════════════════════════════

	# ── Ombre ─────────────────────────────────────────
	var ombre      = _quad(Vector2(SPRITE_W + 0.12, sprite_h + 0.12),
						   Color(0, 0, 0, 0.28), true)
	ombre.position = Vector3(0.04, -0.04, -0.05)
	add_child(ombre)

	# ── Bordure décompte ──────────────────────────────
	var border_node  = MeshInstance3D.new()
	var q_b          = QuadMesh.new()
	q_b.size         = Vector2(SPRITE_W + 0.10, sprite_h + 0.10)
	border_node.mesh = q_b
	_border_mat      = ShaderMaterial.new()
	_border_mat.shader = SHADER_BORDER
	_border_mat.set_shader_parameter("progress",      1.0)
	_border_mat.set_shader_parameter("couleur_plein", Color(1.0, 0.65, 0.1, 1.0))
	_border_mat.set_shader_parameter("couleur_vide",  Color(0.55, 0.55, 0.55, 0.18))
	_border_mat.set_shader_parameter("epaisseur",     0.06)
	border_node.material_override = _border_mat
	border_node.position.z        = -0.02
	add_child(border_node)

	# ── Fond blanc crème ──────────────────────────────
	var fond        = _quad(Vector2(SPRITE_W + 0.02, sprite_h + 0.02),
							Color(1.0, 0.97, 0.88), false)
	fond.position.z = 0.0
	add_child(fond)

	# ── Header orange ─────────────────────────────────
	var header      = _quad(Vector2(SPRITE_W + 0.02, 0.10),
							Color(1.0, 0.62, 0.08), false)
	header.position = Vector3(0.0, (sprite_h + 0.02) * 0.5 - 0.05, 0.01)
	add_child(header)

	# ── Sprite3D (rendu du viewport) ──────────────────
	var sprite        = Sprite3D.new()
	sprite.texture    = _viewport.get_texture()
	sprite.pixel_size = SPRITE_W / float(VP_SIZE.x)
	sprite.position.z = 0.03
	add_child(sprite)

	# ── Queue de bulle ────────────────────────────────
	var queue                = _quad(Vector2(0.18, 0.18),
									 Color(1.0, 0.97, 0.88), false)
	queue.rotation_degrees.z = 45.0
	queue.position           = Vector3(0.0, -(sprite_h * 0.5 + 0.07), 0.0)
	add_child(queue)

func _quad(taille: Vector2, couleur: Color, alpha: bool) -> MeshInstance3D:
	var mi  = MeshInstance3D.new()
	var q   = QuadMesh.new()
	q.size  = taille
	mi.mesh = q
	var mat = StandardMaterial3D.new()
	mat.albedo_color    = couleur
	mat.shading_mode    = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode       = BaseMaterial3D.CULL_DISABLED
	if alpha:
		mat.transparency    = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	else:
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	mi.material_override = mat
	return mi

func _process(_delta: float) -> void:
	# ── Billboard ─────────────────────────────────────
	if _camera == null:
		_camera = get_viewport().get_camera_3d()
		return
	var dir = (global_position - _camera.global_position).normalized()
	if dir.length_squared() > 0.001:
		look_at(global_position + dir, Vector3.UP)

	# ── Décompte de la bordure ────────────────────────
	if _timer == null or _timer.is_stopped() or _border_mat == null:
		return
	var t = clamp(_timer.time_left / PATIENCE_MAX, 0.0, 1.0)
	_border_mat.set_shader_parameter("progress", t)
	var c = Color(1.0, 0.1, 0.1).lerp(Color(1.0, 0.65, 0.1), t)
	_border_mat.set_shader_parameter("couleur_plein", c)

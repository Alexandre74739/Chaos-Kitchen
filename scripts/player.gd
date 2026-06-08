extends CharacterBody3D

const SPEED                = 5.0
const GRAVITY              = -9.8
var   mouse_sensitivity    := 0.003
const JOYSTICK_SENSITIVITY = 0.05
const LEAN_SPEED           = 8.0
const LEAN_MAX_ANGLE       = 6.0
const FOV_NORMAL           = 75.0
const FOV_VISE             = 38.0
const VITESSE_VISE         = 0.4

@onready var spring_arm       = $CameraRoot/SpringArm3D
@onready var interaction_zone = $InteractionZone
@onready var lean_pivot       = $LeanPivot
@onready var anim             = $LeanPivot/AnimPlayerGodot
@onready var camera           = $CameraRoot/SpringArm3D/Camera3D

var main_droite       : Node3D            = null
var particules_marche : GPUParticles3D    = null
var sfx_marche        : AudioStreamPlayer = null

@export var fusil_offset_main : Vector3 = Vector3(0.20, 0.35, 0.0)

var camera_angle        = 0.0
var nearby_interactable = null
var ingredient_en_main  = null
var nom_ingredient_tenu = ""
var fusil_en_main       = false
var fusil_instance      = null

var _reticule           : CanvasLayer = null
var _bras_g             : ColorRect   = null
var _bras_d             : ColorRect   = null
var _bras_h             : ColorRect   = null
var _bras_b             : ColorRect   = null
var _reticule_espace    : float       = 5.0
var _reticule_longueur  : float       = 14.0
var _viser_actif        : bool        = false

func _ready():
	var bs = get_node_or_null("/root/BestScore")
	if bs:
		mouse_sensitivity = bs.get_sensitivity() / 1000.0
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)

	# ── Trouve MainDroite ─────────────────────────────────
	main_droite = find_child("MainDroite", true, false)
	if main_droite == null:
		push_error("MainDroite introuvable")
	else:
		print("MainDroite : " + str(main_droite.get_path()))

	# ── Lance idle_organic au démarrage ───────────────────
	if anim != null:
		if anim.has_animation("idle_organic"):
			anim.play("idle_organic")
		else:
			push_error("Animation idle_organic introuvable")

	# ── Particules de pas au sol ─────────────────────────
	particules_marche = GPUParticles3D.new()
	add_child(particules_marche)
	particules_marche.position     = Vector3(0, -1.15, 0)
	particules_marche.emitting     = false
	particules_marche.one_shot     = false
	particules_marche.amount       = 10
	particules_marche.lifetime     = 0.4
	particules_marche.local_coords = false

	var mat_m = ParticleProcessMaterial.new()
	mat_m.emission_shape       = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat_m.emission_box_extents = Vector3(0.2, 0.005, 0.2)
	mat_m.direction            = Vector3(0, 1, 0)
	mat_m.spread               = 180.0
	mat_m.initial_velocity_min = 0.1
	mat_m.initial_velocity_max = 0.45
	mat_m.gravity              = Vector3(0, -0.2, 0)
	mat_m.scale_min            = 0.25
	mat_m.scale_max            = 0.65

	var grad = Gradient.new()
	grad.set_color(0, Color(0.80, 0.74, 0.62, 0.6))
	grad.set_color(1, Color(0.80, 0.74, 0.62, 0.0))
	var ramp = GradientTexture1D.new()
	ramp.gradient    = grad
	mat_m.color_ramp = ramp
	particules_marche.process_material = mat_m

	var mesh_m    = SphereMesh.new()
	mesh_m.radius = 0.12
	mesh_m.height = 0.03
	particules_marche.draw_pass_1 = mesh_m

	# ── Lecteur dédié aux pas en boucle ───────────────────
	sfx_marche = AudioStreamPlayer.new()
	sfx_marche.stream    = load("res://audio/sfx/marche.mp3")
	sfx_marche.volume_db = -5.0
	sfx_marche.bus       = "SFX"
	sfx_marche.pitch_scale = 1.5
	var stream_marche = sfx_marche.stream as AudioStreamWAV
	if stream_marche:
		stream_marche.loop_mode = AudioStreamWAV.LOOP_FORWARD
	add_child(sfx_marche)

	_creer_reticule()

func _input(event):
	# ── Rotation caméra souris ────────────────────────────
	if event is InputEventMouseMotion:
		var s = mouse_sensitivity * (VITESSE_VISE if _viser_actif else 1.0)
		rotate_y(-event.relative.x * s)
		camera_angle -= event.relative.y * s
		camera_angle = clamp(camera_angle, -0.5, 0.3)
		spring_arm.rotation.x = camera_angle

	# ── Interaction ───────────────────────────────────────
	if event.is_action_pressed("interact"):
		if nearby_interactable != null and nearby_interactable != fusil_instance:
			nearby_interactable.interact(self)
		elif fusil_en_main:
			deposer_fusil()

func _physics_process(delta):
	# ── Gravité ───────────────────────────────────────────
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# ── Déplacement ───────────────────────────────────────
	var direction = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x

	direction = direction.normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()

	# ── Son + poussière de marche ────────────────────────
	var is_moving = direction.length() > 0.1 and is_on_floor()
	if is_moving:
		if not sfx_marche.playing:
			sfx_marche.play()
		particules_marche.emitting = true
	else:
		if sfx_marche.playing:
			sfx_marche.stop()
		particules_marche.emitting = false

	# ── Visée (clic droit / gâchette gauche) ─────────────
	_viser_actif = fusil_en_main and (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or
		Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) > 0.3
	)
	var fov_cible = FOV_VISE if _viser_actif else FOV_NORMAL
	camera.fov = lerp(camera.fov, fov_cible, 12.0 * delta)
	lean_pivot.visible = not _viser_actif

	# ── Caméra manette ────────────────────────────────────
	var joy_sens  = JOYSTICK_SENSITIVITY * (VITESSE_VISE if _viser_actif else 1.0)
	var joy_x     = Input.get_axis("camera_x_left", "camera_x_right")
	var joy_y     = Input.get_axis("camera_y_up", "camera_y_down")
	if abs(joy_x) > 0.1:
		rotate_y(-joy_x * joy_sens)
	if abs(joy_y) > 0.1:
		camera_angle -= joy_y * joy_sens
		camera_angle = clamp(camera_angle, -0.5, 0.3)
		spring_arm.rotation.x = camera_angle

	# ── Animation ─────────────────────────────────────────
	if anim != null:
		if direction.length() > 0.1:
			if anim.current_animation != "idle_jump":
				anim.play("idle_jump")
		else:
			if anim.current_animation != "idle_organic":
				anim.play("idle_organic")

	# ── Fusil suit la main ────────────────────────────────
	if fusil_en_main and fusil_instance != null:
		var camera = $CameraRoot/SpringArm3D/Camera3D
		var base = global_transform.basis.orthonormalized()
		var offset = base.x * fusil_offset_main.x \
			+ Vector3.UP * fusil_offset_main.y \
			+ base.z * fusil_offset_main.z
		fusil_instance.global_position = main_droite.global_position + offset
		fusil_instance.global_rotation = camera.global_rotation

	# ── Détection de secours (corps déjà dans la zone) ────
	if nearby_interactable == null:
		for body in interaction_zone.get_overlapping_bodies():
			if body.has_method("interact") and body != fusil_instance:
				nearby_interactable = body
				break

	# ── Tir (une seule fois par pression, souris et manette) ─
	if Input.is_action_just_pressed("tirer") and fusil_en_main:
		_tirer()

	# ── Animation réticule (bloom / visée) ───────────────
	if fusil_en_main and _bras_g != null:
		var cible_espace : float
		var cible_longueur : float
		if _viser_actif:
			cible_espace   = 1.0
			cible_longueur = 7.0
		elif direction.length() > 0.1:
			cible_espace   = 12.0
			cible_longueur = 14.0
		else:
			cible_espace   = 5.0
			cible_longueur = 14.0
		_reticule_espace   = lerp(_reticule_espace,   cible_espace,   12.0 * delta)
		_reticule_longueur = lerp(_reticule_longueur, cible_longueur, 12.0 * delta)
		var G := int(_reticule_espace)
		var L := int(_reticule_longueur)
		_bras_g.offset_left   = -(G + L) ; _bras_g.offset_right  = -G
		_bras_d.offset_left   =   G      ; _bras_d.offset_right  =  G + L
		_bras_h.offset_top    = -(G + L) ; _bras_h.offset_bottom = -G
		_bras_b.offset_top    =   G      ; _bras_b.offset_bottom =  G + L

	# ── Inclinaison ───────────────────────────────────────
	_appliquer_inclinaison(direction, delta)

# ── Inclinaison du LeanPivot ──────────────────────────────
func _appliquer_inclinaison(direction: Vector3, delta: float):
	if direction.length() > 0.1:
		var dir_locale = lean_pivot.global_transform.basis.inverse() * direction
		var cible_x    = dir_locale.z * LEAN_MAX_ANGLE
		var cible_z    = -dir_locale.x * LEAN_MAX_ANGLE
		lean_pivot.rotation_degrees.x = lerp(
			lean_pivot.rotation_degrees.x, cible_x, LEAN_SPEED * delta)
		lean_pivot.rotation_degrees.z = lerp(
			lean_pivot.rotation_degrees.z, cible_z, LEAN_SPEED * delta)
	else:
		lean_pivot.rotation_degrees.x = lerp(
			lean_pivot.rotation_degrees.x, 0.0, LEAN_SPEED * delta)
		lean_pivot.rotation_degrees.z = lerp(
			lean_pivot.rotation_degrees.z, 0.0, LEAN_SPEED * delta)

# ── Gestion ingrédient ────────────────────────────────────
func tient_ingredient() -> bool:
	return ingredient_en_main != null

func tient_fusil() -> bool:
	return fusil_en_main

func prendre_ingredient(ingredient, nom):
	if fusil_en_main:
		deposer_fusil()
	ingredient_en_main  = ingredient
	nom_ingredient_tenu = nom
	if main_droite != null:
		if ingredient.get_parent() != null:
			ingredient.reparent(main_droite)
		else:
			main_droite.add_child(ingredient)
		ingredient.position = Vector3.ZERO
	print("En main : " + nom)

func deposer_ingredient():
	if ingredient_en_main == null:
		return null
	ingredient_en_main.queue_free()
	ingredient_en_main = null
	nom_ingredient_tenu = ""
	return null

# ── Gestion fusil ─────────────────────────────────────────
func prendre_fusil(fusil):
	if ingredient_en_main != null:
		deposer_ingredient()
	fusil_en_main = true
	fusil_instance = fusil
	if _reticule:
		_reticule.visible = true
	print("Fusil en main")

func deposer_fusil():
	if not fusil_en_main:
		return
	fusil_en_main    = false
	_viser_actif     = false
	lean_pivot.visible = true
	if _reticule:
		_reticule.visible = false
	fusil_instance.etre_pose(self)
	fusil_instance = null
	print("Fusil posé")

func _tirer() -> void:
	AudioManager.jouer_sfx("tir")
	var from  = camera.global_position
	var dir   = -camera.global_transform.basis.z
	var to    = from + dir * 35.0
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var result  = get_world_3d().direct_space_state.intersect_ray(query)
	var hit_pos = result["position"] if result else to

	_flash_canon()
	_creer_tracer(from + dir * 0.4, hit_pos)

	if result:
		_flash_impact(hit_pos)
		if result["collider"].has_method("mourir"):
			result["collider"].mourir()

func _flash_canon() -> void:
	if fusil_instance == null or not is_instance_valid(fusil_instance) \
			or not fusil_instance.is_inside_tree():
		return
	var flash         = OmniLight3D.new()
	flash.light_color = Color(1.0, 0.82, 0.35, 1.0)
	flash.light_energy = 6.0
	flash.omni_range  = 4.0
	get_tree().current_scene.add_child(flash)
	flash.global_position = fusil_instance.global_position
	var tw = create_tween()
	tw.tween_property(flash, "light_energy", 0.0, 0.08)
	tw.tween_callback(flash.queue_free)

func _creer_tracer(from: Vector3, to: Vector3) -> void:
	var dist = from.distance_to(to)
	if dist < 0.1:
		return
	var dir = (to - from).normalized()
	var mid = from + dir * dist * 0.5

	var mat = StandardMaterial3D.new()
	mat.albedo_color     = Color(1.0, 0.92, 0.55, 0.90)
	mat.emission_enabled = true
	mat.emission         = Color(1.0, 0.85, 0.35)
	mat.emission_energy  = 4.0
	mat.transparency     = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode        = BaseMaterial3D.CULL_DISABLED

	var box      = BoxMesh.new()
	box.size     = Vector3(0.025, 0.025, dist)
	var mesh     = MeshInstance3D.new()
	mesh.mesh    = box
	mesh.set_surface_override_material(0, mat)

	get_tree().current_scene.add_child(mesh)
	mesh.global_position = mid
	var up = Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	mesh.global_transform.basis = Basis.looking_at(dir, up)

	var tw = create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.14)
	tw.tween_callback(mesh.queue_free)

func _flash_impact(pos: Vector3) -> void:
	var flash          = OmniLight3D.new()
	flash.light_color  = Color(1.0, 0.6, 0.2, 1.0)
	flash.light_energy = 3.5
	flash.omni_range   = 3.0
	get_tree().current_scene.add_child(flash)
	flash.global_position = pos
	var tw = create_tween()
	tw.tween_property(flash, "light_energy", 0.0, 0.10)
	tw.tween_callback(flash.queue_free)

	var particles           = GPUParticles3D.new()
	particles.amount        = 12
	particles.lifetime      = 0.35
	particles.one_shot      = true
	particles.explosiveness = 0.9
	var pm                        = ParticleProcessMaterial.new()
	pm.emission_shape             = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius     = 0.05
	pm.direction                  = Vector3.UP
	pm.spread                     = 120.0
	pm.initial_velocity_min       = 1.5
	pm.initial_velocity_max       = 3.5
	pm.gravity                    = Vector3(0, -6, 0)
	pm.scale_min                  = 0.04
	pm.scale_max                  = 0.10
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.75, 0.2, 1.0))
	grad.set_color(1, Color(0.5, 0.3, 0.1, 0.0))
	var ramp      = GradientTexture1D.new()
	ramp.gradient = grad
	pm.color_ramp = ramp
	var sm       = SphereMesh.new()
	sm.radius    = 0.04
	sm.height    = 0.08
	particles.process_material = pm
	particles.draw_pass_1      = sm
	get_tree().current_scene.add_child(particles)
	particles.global_position  = pos
	particles.emitting         = true
	var t          = Timer.new()
	t.wait_time    = 1.0
	t.one_shot     = true
	particles.add_child(t)
	t.timeout.connect(particles.queue_free)
	t.start()

# ── Détection proximité ───────────────────────────────────
func _on_body_entered(body):
	if body.has_method("interact"):
		nearby_interactable = body

func _on_body_exited(body):
	if body == nearby_interactable:
		nearby_interactable = null

# ── Réticule de visée ─────────────────────────────────────
func _creer_reticule() -> void:
	_reticule         = CanvasLayer.new()
	_reticule.layer   = 30
	_reticule.visible = false
	add_child(_reticule)

	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticule.add_child(root)

	var blanc  = Color(1.0, 1.0, 1.0, 0.92)
	var ombre  = Color(0.0, 0.0, 0.0, 0.55)
	var G      = 5    # espace central initial
	var L      = 14   # longueur d'un bras
	var ep     = 2    # épaisseur

	# Ombre portée (décalée d'1px) puis trait blanc pour chaque bras
	_bras_g = _segment(root, ombre, blanc, -(G + L), -(G), -ep / 2, ep / 2, true)
	_bras_d = _segment(root, ombre, blanc,   G,  G + L,  -ep / 2, ep / 2, true)
	_bras_h = _segment(root, ombre, blanc, -ep / 2, ep / 2, -(G + L), -G, false)
	_bras_b = _segment(root, ombre, blanc, -ep / 2, ep / 2,   G,  G + L, false)

	# Point central
	_segment(root, ombre, blanc, -2, 2, -2, 2, true)

func _segment(parent: Control, c_ombre: Color, c_fill: Color,
		ol: int, or_: int, ot: int, ob: int, _horizontal: bool) -> ColorRect:
	var s = ColorRect.new()
	s.color          = c_ombre
	s.anchor_left    = 0.5 ; s.anchor_right  = 0.5
	s.anchor_top     = 0.5 ; s.anchor_bottom = 0.5
	s.offset_left    = ol - 1 ; s.offset_right  = or_ + 1
	s.offset_top     = ot - 1 ; s.offset_bottom = ob  + 1
	parent.add_child(s)

	var f = ColorRect.new()
	f.color          = c_fill
	f.anchor_left    = 0.5 ; f.anchor_right  = 0.5
	f.anchor_top     = 0.5 ; f.anchor_bottom = 0.5
	f.offset_left    = ol  ; f.offset_right  = or_
	f.offset_top     = ot  ; f.offset_bottom = ob
	parent.add_child(f)

	return f

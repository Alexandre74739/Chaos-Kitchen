extends CharacterBody3D

const SPEED                = 5.0
const GRAVITY              = -9.8
var   mouse_sensitivity    := 0.003
const JOYSTICK_SENSITIVITY = 0.05
const LEAN_SPEED           = 8.0
const LEAN_MAX_ANGLE       = 6.0

@onready var spring_arm       = $CameraRoot/SpringArm3D
@onready var interaction_zone = $InteractionZone
@onready var lean_pivot       = $LeanPivot
@onready var anim             = $LeanPivot/AnimPlayerGodot

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

func _ready():
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

func _input(event):
	# ── Rotation caméra souris ────────────────────────────
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_angle -= event.relative.y * mouse_sensitivity
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

	# ── Caméra manette ────────────────────────────────────
	var joy_x = Input.get_axis("camera_x_left", "camera_x_right")
	var joy_y = Input.get_axis("camera_y_up", "camera_y_down")
	if abs(joy_x) > 0.1:
		rotate_y(-joy_x * JOYSTICK_SENSITIVITY)
	if abs(joy_y) > 0.1:
		camera_angle -= joy_y * JOYSTICK_SENSITIVITY
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
	print("Fusil en main")

func deposer_fusil():
	if not fusil_en_main:
		return
	fusil_en_main = false
	fusil_instance.etre_pose(self)
	fusil_instance = null
	print("Fusil posé")

func _tirer():
	AudioManager.jouer_sfx("tir")
	var camera = $CameraRoot/SpringArm3D/Camera3D
	var from = camera.global_position
	var dir  = -camera.global_transform.basis.z
	var to   = from + dir * 30.0
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result and result["collider"].has_method("mourir"):
		result["collider"].mourir()

# ── Détection proximité ───────────────────────────────────
func _on_body_entered(body):
	if body.has_method("interact"):
		nearby_interactable = body

func _on_body_exited(body):
	if body == nearby_interactable:
		nearby_interactable = null

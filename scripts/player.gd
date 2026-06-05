extends CharacterBody3D

const SPEED                = 5.0
const GRAVITY              = -9.8
const MOUSE_SENSITIVITY    = 0.003
const JOYSTICK_SENSITIVITY = 0.05
const LEAN_SPEED           = 8.0
const LEAN_MAX_ANGLE       = 6.0

@onready var spring_arm       = $CameraRoot/SpringArm3D
@onready var interaction_zone = $InteractionZone
@onready var lean_pivot       = $LeanPivot
@onready var anim             = $LeanPivot/AnimPlayerGodot

var main_droite : Node3D          = null
var particules  : GPUParticles3D  = null
var sfx_marche  : AudioStreamPlayer = null

var camera_angle        = 0.0
var nearby_interactable = null
var ingredient_en_main  = null
var nom_ingredient_tenu = ""

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

	# ── Crée les particules d'atterrissage ────────────────
	particules = GPUParticles3D.new()
	add_child(particules)
	particules.position      = Vector3(0, 0.05, 0)
	particules.emitting      = false
	particules.one_shot      = true
	particules.explosiveness = 0.9
	particules.amount        = 12

	var mat = ParticleProcessMaterial.new()
	mat.emission_shape         = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.2
	mat.direction              = Vector3(0, 1, 0)
	mat.spread                 = 60.0
	mat.initial_velocity_min   = 1.0
	mat.initial_velocity_max   = 2.5
	mat.gravity                = Vector3(0, -6, 0)
	mat.scale_min              = 0.05
	mat.scale_max              = 0.15
	particules.process_material = mat

	var mesh_part    = SphereMesh.new()
	mesh_part.radius = 0.05
	mesh_part.height = 0.1
	particules.draw_pass_1 = mesh_part

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
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_angle -= event.relative.y * MOUSE_SENSITIVITY
		camera_angle = clamp(camera_angle, -0.5, 0.3)
		spring_arm.rotation.x = camera_angle

	# ── Interaction ───────────────────────────────────────
	if event.is_action_pressed("interact"):
		if nearby_interactable != null:
			nearby_interactable.interact(self)

	# ── Libère la souris ──────────────────────────────────
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	var etait_en_air = not is_on_floor()

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

	# ── Son de marche en boucle ───────────────────────────
	var is_moving = direction.length() > 0.1 and is_on_floor()
	if is_moving:
		if not sfx_marche.playing:
			sfx_marche.play()
	else:
		if sfx_marche.playing:
			sfx_marche.stop()

	# ── Particules à l'atterrissage ───────────────────────
	if etait_en_air and is_on_floor():
		particules.restart()
		particules.emitting = true

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

func prendre_ingredient(ingredient, nom):
	ingredient_en_main  = ingredient
	nom_ingredient_tenu = nom
	if main_droite != null:
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

# ── Détection proximité ───────────────────────────────────
func _on_body_entered(body):
	if body.has_method("interact"):
		nearby_interactable = body

func _on_body_exited(body):
	if body == nearby_interactable:
		nearby_interactable = null

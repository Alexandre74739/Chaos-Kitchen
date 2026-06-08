extends CharacterBody3D

signal mort

const RAT_GLB   = preload("res://assets/Rat.glb")
const VITESSE   = 0.9
const GRAVITY   = -9.8
const BOB_AMP   = 0.025
const BOB_SPEED = 8.0

var _modele    : Node3D  = null
var _cible     : Vector3 = Vector3.ZERO
var _temps_bob : float   = 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask  = 1

	var shape      = CapsuleShape3D.new()
	shape.radius   = 0.13
	shape.height   = 0.26
	var col        = CollisionShape3D.new()
	col.shape      = shape
	col.position.y = 0.13
	add_child(col)

	_modele                    = RAT_GLB.instantiate()
	_modele.scale              = Vector3(0.6, 0.6, 0.6)
	_modele.rotation_degrees.y = 180.0
	add_child(_modele)

	_choisir_cible()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	var diff = (_cible - global_position) * Vector3(1, 0, 1)
	if diff.length() < 0.3:
		_choisir_cible()
	else:
		var dir    = diff.normalized()
		velocity.x = dir.x * VITESSE
		velocity.z = dir.z * VITESSE
		look_at(global_position + Vector3(dir.x, 0.0, dir.z), Vector3.UP)

	move_and_slide()

	_temps_bob     += delta * BOB_SPEED
	if _modele:
		_modele.position.y = sin(_temps_bob) * BOB_AMP

func _choisir_cible() -> void:
	var angle = randf() * TAU
	var dist  = randf_range(1.5, 4.0)
	_cible    = global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

func mourir() -> void:
	mort.emit()
	queue_free()

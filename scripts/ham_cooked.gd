extends RigidBody3D

const HAM_VISUAL = preload("res://assets/food_ingredient_ham_cooked.fbx")

func _ready():
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = false

func _process(delta):
	if freeze:
		return
	rotate_y(delta * 2.0)

func interact(joueur):
	AudioManager.jouer_sfx("prendre_ingredient")
	if joueur.tient_ingredient():
		joueur.deposer_ingredient()
	var visuel = HAM_VISUAL.instantiate()
	visuel.scale = Vector3(0.9, 0.9, 0.9)
	joueur.prendre_ingredient(visuel, "viande")
	visuel.position = Vector3(0, 0.18, 0)
	queue_free()

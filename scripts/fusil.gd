extends RigidBody3D

var etat = "au_sol"

func _ready():
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = true

func _process(delta):
	if etat == "au_sol":
		rotate_y(delta * 1.5)

func interact(joueur):
	if etat == "au_sol":
		etat = "en_main"
		freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		freeze = true
		collision_layer = 0
		collision_mask = 0
		joueur.prendre_fusil(self)

func etre_pose(joueur):
	etat = "au_sol"
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = true
	collision_layer = 1
	collision_mask = 1
	global_position = joueur.global_position + Vector3(0, 0.3, 0) - joueur.transform.basis.z * 0.6

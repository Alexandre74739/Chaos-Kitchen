extends AnimatableBody3D

@export var angle_ouverture : float = 90.0
@export var vitesse         : float = 5
@export var delai_fermeture : float = 0.5

@onready var pivot = $PivotPorte

enum EtatPorte { FERMEE, OUVERTURE, OUVERTE, FERMETURE }
var etat         : EtatPorte = EtatPorte.FERMEE
var angle_actuel : float     = 0.0
var angle_cible  : float     = 90.0
var joueurs_zone : int       = 0
var timer_ferme  : float     = 0.0

func _ready():
	$ZoneDetection.body_entered.connect(_on_body_entered)
	$ZoneDetection.body_exited.connect(_on_body_exited)

func _physics_process(delta):
	match etat:

		EtatPorte.OUVERTURE:
			angle_actuel = move_toward(angle_actuel, angle_cible, vitesse * delta * 60)
			pivot.rotation_degrees.y = angle_actuel
			if abs(angle_actuel - angle_cible) < 0.1:
				angle_actuel = angle_cible
				etat = EtatPorte.OUVERTE
				print("Porte ouverte")

		EtatPorte.OUVERTE:
			# Ne commence le timer que si personne n'est dans la zone
			if joueurs_zone <= 0:
				timer_ferme -= delta
				if timer_ferme <= 0:
					etat = EtatPorte.FERMETURE
			else:
				# Réinitialise le timer tant que le joueur est là
				timer_ferme = delai_fermeture

		EtatPorte.FERMETURE:
			# Si le joueur revient pendant la fermeture → rouvre
			if joueurs_zone > 0:
				etat = EtatPorte.OUVERTURE
				return
			angle_actuel = move_toward(angle_actuel, 0.0, vitesse * delta * 60)
			pivot.rotation_degrees.y = angle_actuel
			if abs(angle_actuel) < 0.1:
				angle_actuel = 0.0
				etat = EtatPorte.FERMEE
				print("Porte fermée")

func _on_body_entered(body):
	if not body is CharacterBody3D:
		return

	joueurs_zone += 1

	if etat == EtatPorte.FERMEE:
		# Détecte de quel côté arrive le joueur
		# to_local() convertit la position du joueur en coordonnées locales de la porte
		var pos_locale = to_local(body.global_position)

		# Si le joueur est du côté positif Z → ouvre dans un sens
		# Si côté négatif Z → ouvre dans l'autre sens
		if pos_locale.z > 0:
			angle_cible = angle_ouverture
		else:
			angle_cible = -angle_ouverture

		timer_ferme = delai_fermeture
		etat = EtatPorte.OUVERTURE
		print("Porte : ouverture vers " + str(angle_cible) + "°")

func _on_body_exited(body):
	if not body is CharacterBody3D:
		return
	joueurs_zone -= 1
	# Démarre le timer de fermeture quand le joueur quitte
	if joueurs_zone <= 0:
		joueurs_zone = 0
		timer_ferme = delai_fermeture
		print("Joueur parti — fermeture dans " + str(delai_fermeture) + "s")

extends StaticBody3D

# ── Assets burger (glisse tes scènes dans l'Inspector) ────
@export var asset_pain_bas  : PackedScene
@export var asset_pain_haut : PackedScene
@export var asset_salade    : PackedScene
@export var asset_viande    : PackedScene
@export var asset_fromage   : PackedScene
@export var asset_tomate    : PackedScene

# ── Hauteurs par ingrédient (à ajuster dans l'Inspector) ──
@export var hauteur_pain_bas  : float = 0.15
@export var hauteur_pain_haut : float = 0.15
@export var hauteur_salade    : float = 0.08
@export var hauteur_viande    : float = 0.12
@export var hauteur_fromage   : float = 0.06
@export var hauteur_tomate    : float = 0.10

# ── Position de départ de la pile (X Y Z dans l'Inspector) ─
@export var offset_burger : Vector3 = Vector3(0.5, 1, 0)

# ── État interne ──────────────────────────────────────────
var ingredients_poses : Array = []
var hauteur_actuelle  : float = 0.0
var burger_node       : Node3D
var burger_ferme      : bool  = false

func _ready():
	burger_node = Node3D.new()
	burger_node.name = "BurgerPile"
	burger_node.position = offset_burger
	add_child(burger_node)

# ── Appelé par le joueur quand il appuie sur E ────────────
func interact(joueur):
	# Burger fermé → le joueur le prend en main
	if burger_ferme:
		_donner_burger_au_joueur(joueur)
		return

	if not joueur.tient_ingredient():
		print("Rien en main — apporte un ingrédient")
		return

	var nom = joueur.nom_ingredient_tenu

	# Convertit "pain" en pain_bas ou pain_haut dynamiquement
	if nom == "pain":
		if ingredients_poses.is_empty():
			nom = "pain_bas"
		elif not "pain_haut" in ingredients_poses:
			nom = "pain_haut"
		else:
			print("Le burger est déjà fermé")
			return

	if not _peut_poser(nom):
		return

	_poser_ingredient(nom, joueur)

# ── Pose l'ingrédient sur la pile ─────────────────────────
func _poser_ingredient(nom: String, joueur):
	var scene = _get_asset(nom)
	if scene == null:
		push_error("Asset non assigné dans l'Inspector pour : " + nom)
		return

	var mesh = scene.instantiate()
	burger_node.add_child(mesh)
	mesh.position = Vector3(0, hauteur_actuelle, 0)
	hauteur_actuelle += _get_hauteur(nom)
	ingredients_poses.append(nom)

	joueur.deposer_ingredient()
	print("Posé : " + nom + " (pile : " + str(hauteur_actuelle) + ")")

	if nom == "pain_haut":
		burger_ferme = true
		print("Burger fermé ! Appuie sur E pour le prendre")

# ── Donne le burger entier au joueur ──────────────────────
func _donner_burger_au_joueur(joueur):
	if joueur.tient_ingredient():
		print("Les mains sont pleines !")
		return

	remove_child(burger_node)
	joueur.prendre_ingredient(burger_node, "burger")
	print("Burger pris en main !")

	_reset()

# ── Vérifie si l'ingrédient peut être posé ────────────────
func _peut_poser(nom: String) -> bool:
	if ingredients_poses.is_empty():
		if nom != "pain_bas":
			print("Commence par le pain du bas !")
			return false
		return true

	if nom == "pain_haut":
		if ingredients_poses.size() < 2:
			print("Ajoute des ingrédients avant de fermer le burger")
			return false
		return true

	if nom in ingredients_poses:
		print(nom + " est déjà dans le burger")
		return false

	var recette = ["pain_bas", "salade", "viande", "fromage", "tomate", "pain_haut"]
	if nom not in recette:
		print(nom + " n'est pas un ingrédient du burger")
		return false

	return true

# ── Remet le plan de travail à zéro ───────────────────────
func _reset():
	burger_node = Node3D.new()
	burger_node.name = "BurgerPile"
	burger_node.position = offset_burger
	add_child(burger_node)
	ingredients_poses.clear()
	hauteur_actuelle = 0.0
	burger_ferme     = false
	print("Plan de travail prêt pour le prochain burger")

# ── Retourne l'asset selon le nom ─────────────────────────
func _get_asset(nom: String) -> PackedScene:
	match nom:
		"pain_bas"  : return asset_pain_bas
		"pain_haut" : return asset_pain_haut
		"salade"    : return asset_salade
		"viande"    : return asset_viande
		"fromage"   : return asset_fromage
		"tomate"    : return asset_tomate
	return null

# ── Retourne la hauteur selon le nom ──────────────────────
func _get_hauteur(nom: String) -> float:
	match nom:
		"pain_bas"  : return hauteur_pain_bas
		"pain_haut" : return hauteur_pain_haut
		"salade"    : return hauteur_salade
		"viande"    : return hauteur_viande
		"fromage"   : return hauteur_fromage
		"tomate"    : return hauteur_tomate
	return 0.1

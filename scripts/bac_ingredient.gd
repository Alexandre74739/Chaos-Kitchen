extends StaticBody3D

@export var ingredient_scene : PackedScene
@export var nom_ingredient   : String = "Ingrédient"

func interact(joueur):
	# Remplace l'ingrédient même si les mains sont pleines
	if joueur.tient_ingredient():
		joueur.deposer_ingredient()
		print("Ingrédient remplacé")

	var ingredient = ingredient_scene.instantiate()
	joueur.prendre_ingredient(ingredient, nom_ingredient)

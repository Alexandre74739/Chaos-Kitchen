extends Node3D

func _ready():
	# Joue l'intro puis lance l'ambiance
	AudioManager.jouer_musique("ambiance")

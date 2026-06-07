extends Node

# ── Références aux lecteurs audio ────────────────────────
var musique_player   : AudioStreamPlayer
var ambiance_player  : AudioStreamPlayer
var sfx_players      : Array[AudioStreamPlayer] = []
var nb_sfx_players   : int = 8  # pool de lecteurs simultanés

# ── Catalogue des sons ────────────────────────────────────
var catalogue : Dictionary = {
	# Musiques
	"intro"              : "res://audio/musique/intro.mp3",
	"ambiance"           : "res://audio/musique/ambiance.wav",
	# Effets
	"porte"              : "res://audio/sfx/porte.mp3",
	"marche"             : "res://audio/sfx/marche.mp3",
	"prendre_ingredient" : "res://audio/sfx/prendre_ingredient.mp3",
	"poser_ingredient"   : "res://audio/sfx/poser_ingredient.mp3",
	"tir"                : "res://audio/sfx/tir.mp3",
}

func _ready():
	# ── Lecteur musique principale ────────────────────────
	musique_player = AudioStreamPlayer.new()
	musique_player.bus = "Musique"
	add_child(musique_player)

	# ── Lecteur ambiance (boucle en fond) ─────────────────
	ambiance_player = AudioStreamPlayer.new()
	ambiance_player.bus = "Ambiance"
	ambiance_player.volume_db = -6.0
	add_child(ambiance_player)

	# ── Pool de lecteurs pour les effets ──────────────────
	# Plusieurs lecteurs permettent de jouer plusieurs sons
	# en même temps sans qu'ils se coupent entre eux
	for i in nb_sfx_players:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_players.append(p)

# ── Joue un effet sonore ──────────────────────────────────
func jouer_sfx(nom: String, volume: float = 0.0):
	if not catalogue.has(nom):
		push_error("AudioManager : son introuvable → " + nom)
		return

	# Trouve un lecteur libre dans le pool
	var player = _get_lecteur_libre()
	if player == null:
		return  # tous les lecteurs sont occupés

	var stream = load(catalogue[nom])
	if stream == null:
		push_error("AudioManager : fichier introuvable → " + catalogue[nom])
		return

	player.stream    = stream
	player.volume_db = volume
	player.play()

# ── Joue la musique principale (pas de boucle) ────────────
func jouer_musique(nom: String, volume: float = 0.0):
	if not catalogue.has(nom):
		push_error("AudioManager : musique introuvable → " + nom)
		return

	var stream = load(catalogue[nom])
	if stream == null:
		return

	musique_player.stream    = stream
	musique_player.volume_db = volume
	musique_player.play()

# ── Lance l'ambiance en boucle infinie ───────────────────
func jouer_ambiance(nom: String, volume: float = -6.0):
	if not catalogue.has(nom):
		push_error("AudioManager : ambiance introuvable → " + nom)
		return

	var stream = load(catalogue[nom])
	if stream == null:
		return

	ambiance_player.stream      = stream
	ambiance_player.volume_db   = volume
	ambiance_player.pitch_scale = 1.0

	if not ambiance_player.finished.is_connected(_on_ambiance_finie):
		ambiance_player.finished.connect(_on_ambiance_finie)

	ambiance_player.play()

func _on_ambiance_finie():
	ambiance_player.play()

# ── Arrête l'ambiance ─────────────────────────────────────
func arreter_ambiance():
	if ambiance_player.finished.is_connected(_on_ambiance_finie):
		ambiance_player.finished.disconnect(_on_ambiance_finie)
	ambiance_player.stop()

# ── Arrête la musique principale ──────────────────────────
func arreter_musique():
	musique_player.stop()

# ── Change le volume global d'un bus ─────────────────────
func set_volume(bus: String, volume_db: float):
	var idx = AudioServer.get_bus_index(bus)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, volume_db)

# ── Trouve un lecteur SFX libre dans le pool ─────────────
func _get_lecteur_libre() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	# Si tous occupés → prend le premier (coupe le plus vieux)
	return sfx_players[0]

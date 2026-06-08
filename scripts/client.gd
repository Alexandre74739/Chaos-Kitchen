extends StaticBody3D

signal servi(correct: bool)
signal parti
signal tue

const PATIENCE              = 60.0
const HAM_SCENE             = preload("res://entities/items/food_ingredient_ham_cooked.tscn")
const BULLE_SCRIPT          = preload("res://scripts/bulle_commande.gd")
const INGREDIENTS_MILIEU    = ["salade", "viande", "fromage", "tomate"]

@onready var anim           = $Pivot/AnimPlayerGodot
@onready var timer_patience = $PatienceTimer

var commande : Array   = []
var bulle    : Node3D  = null

func _ready() -> void:
	anim.play("idle_organic")
	timer_patience.wait_time = PATIENCE
	timer_patience.one_shot  = true
	timer_patience.start()
	timer_patience.timeout.connect(_on_patience_epuisee)

	commande = _generer_commande()
	_creer_bulle()

# ── Génère une recette aléatoire avec pain_bas/pain_haut obligatoires ──
func _generer_commande() -> Array:
	var milieux = INGREDIENTS_MILIEU.duplicate()
	milieux.shuffle()
	var nb      = randi_range(1, milieux.size())
	var recette = ["pain_bas"]
	for i in range(nb):
		recette.append(milieux[i])
	recette.append("pain_haut")
	return recette

func _creer_bulle() -> void:
	bulle = Node3D.new()
	bulle.set_script(BULLE_SCRIPT)
	add_child(bulle)
	bulle.setup(commande, timer_patience)

# ── Interaction joueur : E ou manette ─────────────────────────
func interact(player) -> void:
	if player.nom_ingredient_tenu != "burger":
		return
	var burger      = player.ingredient_en_main
	var ingredients = burger.get_meta("ingredients", [])
	var correct     = _verifier_commande(ingredients)
	player.deposer_ingredient()
	AudioManager.jouer_sfx("win_pts" if correct else "loose_pts")
	servi.emit(correct)
	queue_free()

# ── Compare les ingrédients du burger avec la commande ────────
func _verifier_commande(burger: Array) -> bool:
	if burger.size() != commande.size():
		return false
	var c_cmd = {}
	var c_bur = {}
	for i in commande:
		c_cmd[i] = c_cmd.get(i, 0) + 1
	for i in burger:
		c_bur[i] = c_bur.get(i, 0) + 1
	return c_cmd == c_bur

# ── Mort par le fusil ──────────────────────────────────────────
func mourir() -> void:
	timer_patience.stop()
	var ham = HAM_SCENE.instantiate()
	get_parent().add_child(ham)
	ham.global_position = global_position + Vector3(0, 0.5, 0)
	tue.emit()
	queue_free()

func _on_patience_epuisee() -> void:
	parti.emit()
	queue_free()

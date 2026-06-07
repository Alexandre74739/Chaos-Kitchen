extends StaticBody3D

signal servi
signal parti

const PATIENCE = 45.0

@onready var anim            = $Pivot/AnimPlayerGodot
@onready var timer_patience  = $PatienceTimer

func _ready():
	anim.play("idle_organic")
	timer_patience.wait_time = PATIENCE
	timer_patience.one_shot  = true
	timer_patience.start()
	timer_patience.timeout.connect(_on_patience_epuisee)

func interact(player):
	if player.nom_ingredient_tenu == "burger":
		player.deposer_ingredient()
		servi.emit()
		queue_free()

func _on_patience_epuisee():
	parti.emit()
	queue_free()

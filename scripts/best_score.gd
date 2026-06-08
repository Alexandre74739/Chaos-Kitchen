extends Node

const SAVE_PATH = "user://best_score.json"

var _best        : int   = 0
var _sensitivity : float = 3.0

func _ready() -> void:
	_charger()

func get_best() -> int:
	return _best

func update(score: int) -> void:
	if score > _best:
		_best = score
		_sauvegarder()

func get_sensitivity() -> float:
	return _sensitivity

func update_sensitivity(val: float) -> void:
	_sensitivity = val
	_sauvegarder()

func _charger() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		if data is Dictionary:
			if "best" in data:
				_best = int(data["best"])
			if "sensitivity" in data:
				_sensitivity = float(data["sensitivity"])

func _sauvegarder() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"best": _best, "sensitivity": _sensitivity}))

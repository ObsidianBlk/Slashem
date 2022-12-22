extends MarginContainer


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _progress : ProgressBar = $HBoxContainer/ProgressBar

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func update_hp(hp : float, max_hp : float) -> void:
	if _progress:
		_progress.value = (hp / max_hp) * 100.0


extends Node2D



# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _score : Control = $UI/Score
@onready var _death_screen : Control = $UI/DeathScreen

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_ghost_killed() -> void:
	_score.add_score(1)

func _on_player_killed():
	_death_screen.visible = true

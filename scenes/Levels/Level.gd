extends Node2D


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_player_start() -> Vector2:
	for child in get_children():
		if child.name == &"PlayerStart" and child is Node2D:
			return child.global_position
	return Vector2.ZERO

func clear_moblings() -> void:
	for child in get_children():
		if child.is_in_group(&"mobling"):
			child.queue_free()

extends Node2D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal ghost_killed()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GHOST : PackedScene = preload("res://objects/ghost/Ghost.tscn")
const GROUP_OF_INTEREST = &"ghost"
const MAX_GHOSTS : int = 10
const SPAWN_DELAY : float = 0.25


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var sprite : Sprite2D = $Sprite2D

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	sprite.visible = false
	var timer : SceneTreeTimer = get_tree().create_timer(SPAWN_DELAY)
	timer.timeout.connect(_on_timeout)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_ghost_killed() -> void:
	ghost_killed.emit()

func _on_timeout() -> void:
	var glist : Array = get_tree().get_nodes_in_group(GROUP_OF_INTEREST)
	if glist.size() < MAX_GHOSTS:
		var ghost = GHOST.instantiate()
		if ghost:
			ghost.killed.connect(_on_ghost_killed)
			var parent = get_parent()
			if parent:
				parent.add_child(ghost)
				ghost.global_position = global_position
	
	var timer : SceneTreeTimer = get_tree().create_timer(SPAWN_DELAY)
	timer.timeout.connect(_on_timeout)

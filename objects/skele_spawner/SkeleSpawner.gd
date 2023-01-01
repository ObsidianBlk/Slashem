@tool
extends Node2D

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SKELE : PackedScene = preload("res://objects/skele/Skele.tscn")
const GROUP_OF_INTEREST : StringName = &"skele"
const MAX_SKELE : int = 20
const SPAWN_DELAY : float = 1.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var spawn_radius : float = 1.0 :	set = set_spawn_radius


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _sprite : Sprite2D = $Sprite2D

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_spawn_radius(r : float) -> void:
	if r >= 0.0:
		spawn_radius = r
		queue_redraw()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if not Engine.is_editor_hint():
		_sprite.visible = false
		var timer : SceneTreeTimer = get_tree().create_timer(SPAWN_DELAY)
		timer.timeout.connect(_on_timeout)
	else:
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_arc(Vector2.ZERO, spawn_radius, 0.0, deg_to_rad(360.0), 32, Color.WHEAT, 1.0, true)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_timeout() -> void:
	var glist : Array = get_tree().get_nodes_in_group(GROUP_OF_INTEREST)
	if glist.size() < MAX_SKELE:
		var skele = SKELE.instantiate()
		if skele:
			var parent = get_parent()
			if parent:
				parent.add_child(skele)
				var offset : Vector2 = Vector2.UP * randf_range(0, spawn_radius)
				offset = offset.rotated(deg_to_rad(randf_range(-180.0, 180.0)))
				skele.global_position = global_position + offset
	
	var timer : SceneTreeTimer = get_tree().create_timer(SPAWN_DELAY)
	timer.timeout.connect(_on_timeout)


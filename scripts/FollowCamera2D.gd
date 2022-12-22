extends Camera2D
class_name FollowCamera2D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const LERP_RATE : float = 0.9

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var target_node_path : NodePath = ^""

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _target : WeakRef = weakref(null)


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_target_node_path(tnp : NodePath) -> void:
	if tnp != target_node_path:
		target_node_path = tnp
		_UpdateTarget(true)


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateTarget()

func _process(_delta : float) -> void:
	var target : Node2D = _target.get_ref()
	if target != null:
		global_position = lerp(global_position, target.global_position, LERP_RATE)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateTarget(force : bool = false) -> void:
	if force:
		_target = weakref(null)
	
	if _target.get_ref() == null:
		if target_node_path != ^"":
			var tn = get_node_or_null(target_node_path)
			if tn is Node2D:
				_target = weakref(tn)



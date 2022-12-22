extends CharacterBody2D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal killed()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const TARGET_GROUP : StringName = &"player"
const SPEED : float = 50.0
const ATTACK_RATE : float = 0.5
const DAMAGE : float = 0.3


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _target : WeakRef = weakref(null)
var _target_attackable : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var sprite : Sprite2D = $Sprite2D
@onready var agent : NavigationAgent2D = $NAgent

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _physics_process(delta : float) -> void:
	_UpdateTarget()
	var target : Node2D = _target.get_ref()
	if target != null:
		agent.target_location = target.global_position
	else:
		_target_attackable = false
	
	if agent.is_target_reachable() and not agent.is_target_reached():
		var nloc : Vector2 = agent.get_next_location()
		var dir : Vector2 = global_position.direction_to(nloc)
		velocity += ((dir * SPEED) - velocity) * delta
		sprite.flip_h = velocity.x < 0
		move_and_slide()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateTarget() -> void:
	if _target.get_ref() == null:
		var tlist = get_tree().get_nodes_in_group(TARGET_GROUP)
		if tlist.size() > 0 and tlist[0] is Node2D:
			_target = weakref(tlist[0])

func _AttackTarget() -> void:
	if _target.get_ref() == null:
		_target_attackable = false
	if _target_attackable:
		_target.get_ref().hurt(DAMAGE)
		var timer : SceneTreeTimer = get_tree().create_timer(ATTACK_RATE)
		timer.timeout.connect(_AttackTarget)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func kill() -> void:
	set_physics_process(false)
	# TODO: Animate Death
	killed.emit()
	queue_free()

func _on_attack_zone_body_entered(body : Node2D) -> void:
	if _target.get_ref() == body and _target_attackable != true:
		_target_attackable = true
		_AttackTarget()

func _on_attack_zone_body_exited(body : Node2D) -> void:
	if _target.get_ref() == null or _target.get_ref() == body:
		_target_attackable = false

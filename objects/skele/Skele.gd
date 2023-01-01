extends CharacterBody2D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal killed()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const TARGET_GROUP : StringName = &"player"
const SPEED : float = 30.0
const DAMAGE : float = 1.5
const ATT_DRAG : float = 0.2
const ATT_DUR : float = 0.5

const MAX_HITS : int = 2

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var skele_color : Color = Color.WHEAT :				set = set_skele_color
@export var ground_color : Color = Color.SIENNA :			set = set_ground_color

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _target : WeakRef = weakref(null)
var _target_last_pos : Vector2 = Vector2.ZERO

var _appeared : bool = false
var _spawned : bool = false

var _hits : int = 0


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _spawn : Sprite2D = $Spawn
@onready var _head : Sprite2D = $Character/Body/Head
@onready var _body : Sprite2D = $Character/Body/Body
@onready var _arm_l : Sprite2D = $Character/Body/ArmL
@onready var _arm_r : Sprite2D = $Character/Body/ArmR
@onready var _leg_l : Sprite2D = $Character/LegL
@onready var _leg_r : Sprite2D = $Character/LegR

@onready var _anim : AnimationPlayer = $Anim
@onready var _agent : NavigationAgent2D = $NAgent


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_skele_color(c : Color) -> void:
	if skele_color != c:
		skele_color = c
		_UpdateShaderColor()

func set_ground_color(c : Color) -> void:
	if ground_color != c:
		ground_color = c
		_UpdateShaderColor()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateShaderColor()
	_anim.play("appear")

func _physics_process(delta : float) -> void:
	if Engine.is_editor_hint() or not _spawned or _anim.current_animation == &"attack":
		return
	
	_UpdateTarget()
	var target : Node2D = _target.get_ref()
	if target != null:
		if target.global_position != _target_last_pos:
			var angle : float = deg_to_rad(randf_range(0.0, 360.0))
			_target_last_pos = target.global_position
			_agent.target_location = target.global_position + (Vector2.UP * 6.0).rotated(angle)
	
	if _agent.is_target_reachable() and not _agent.is_target_reached():
		var nloc : Vector2 = _agent.get_next_location()
		var dir : Vector2 = global_position.direction_to(nloc)
		velocity += ((dir * SPEED) - velocity) * delta
		move_and_slide()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateSpriteColor(sp : Sprite2D, c : Color) -> void:
	if sp != null:
		var mat : ShaderMaterial = sp.get_material()
		if mat != null:
			mat.set_shader_parameter("color", c)

func _UpdateShaderColor() -> void:
	_UpdateSpriteColor(_spawn, ground_color)
	_UpdateSpriteColor(_head, skele_color)
	_UpdateSpriteColor(_body, skele_color)
	_UpdateSpriteColor(_arm_l, skele_color)
	_UpdateSpriteColor(_arm_r, skele_color)
	_UpdateSpriteColor(_leg_l, skele_color)
	_UpdateSpriteColor(_leg_r, skele_color)

func _UpdateTarget() -> void:
	if _target.get_ref() == null:
		var tlist = get_tree().get_nodes_in_group(TARGET_GROUP)
		if tlist.size() > 0 and tlist[0] is Node2D:
			_target = weakref(tlist[0])

func _AttackTarget() -> void:
	var target : Node2D = _target.get_ref()
	if target != null:
		target.hurt(DAMAGE, ATT_DRAG, ATT_DUR)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func can_kill() -> bool:
	return _spawned

func kill() -> void:
	if Engine.is_editor_hint():
		return
	
	_hits += 1
	if _hits >= MAX_HITS:
		set_physics_process(false)
		killed.emit()
		Statistics.mob_killed()
		#anim.play("death")
		#sfx.play_group(&"death")
		#await anim.animation_finished
		queue_free()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_animation_finished(anim_name : StringName) -> void:
	match anim_name:
		&"appear":
			_appeared = true
		&"spawn":
			_spawned = true
		&"attack":
			_anim.play("idle")

func _on_AttackArea_body_entered(body : Node2D) -> void:
	if _spawned and _anim.current_animation != &"attack":
		if body.is_in_group(TARGET_GROUP) and body == _target.get_ref():
			_anim.play(&"attack")

func _on_wake_area_body_entered(body):
	if not _appeared:
		return
	elif not _spawned:
		if body.is_in_group(TARGET_GROUP) and _anim.current_animation != &"spawn":
			_anim.play(&"spawn")

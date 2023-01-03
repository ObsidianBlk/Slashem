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
const HIT_PUSH_DUR : float = 1.0

const WAKEUP_TIME : float = 5.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var skele_color : Color = Color.WHEAT :				set = set_skele_color
@export var skele_dead_color : Color = Color.ROSY_BROWN
@export var ground_color : Color = Color.SIENNA :			set = set_ground_color

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _target : WeakRef = weakref(null)
var _target_last_pos : Vector2 = Vector2.ZERO
var _target_attackable : bool = false

var _wake_body_seen : bool = false
var _appeared : bool = false
var _spawned : bool = false

var _hits : int = 0
var _hit_dir : Vector2 = Vector2.ZERO


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
	if Engine.is_editor_hint() or _anim.current_animation == "death":
		return
	
	_UpdateTarget()
	if not _spawned:
		return
	
	if _anim.current_animation == &"attack":
		if _hit_dir.length_squared() > 0.0:
			velocity += ((_hit_dir * SPEED) - velocity) * delta
			move_and_slide()
		else:
			velocity = Vector2.ZERO
		return
	
	if _target_attackable and _hit_dir.length_squared() <= 0.0:
		_anim.play(&"attack")
		return
	
	var target : Node2D = _target.get_ref()
	if target != null:
		if target.global_position != _target_last_pos:
			var angle : float = deg_to_rad(randf_range(0.0, 360.0))
			_target_last_pos = target.global_position
			_agent.target_location = target.global_position + (Vector2.UP * 6.0).rotated(angle)
	
	if _agent.is_target_reachable() and not _agent.is_target_reached():
		var nloc : Vector2 = _agent.get_next_location()
		var dir : Vector2 = _hit_dir
		if _hit_dir.length_squared() <= 0.0:
			dir = global_position.direction_to(nloc)
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

func _UpdateSkeleColor(c : Color) -> void:
	_UpdateSpriteColor(_head, c)
	_UpdateSpriteColor(_body, c)
	_UpdateSpriteColor(_arm_l, c)
	_UpdateSpriteColor(_arm_r, c)
	_UpdateSpriteColor(_leg_l, c)
	_UpdateSpriteColor(_leg_r, c)

func _UpdateShaderColor() -> void:
	_UpdateSpriteColor(_spawn, ground_color)
	_UpdateSkeleColor(skele_color)

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
	if Engine.is_editor_hint() or _anim.current_animation == "death":
		return
	
	_hits += 1
	if _hits >= MAX_HITS:
		set_physics_process(false)
		killed.emit()
		Statistics.mob_killed()
		_UpdateSkeleColor(skele_dead_color)
		_anim.play("death")
		#sfx.play_group(&"death")
		await _anim.animation_finished
		queue_free()
	elif _hit_dir.length_squared() <= 0.0:
		var target = _target.get_ref()
		if target != null:
			_hit_dir = target.global_position.direction_to(global_position)
			var timer : SceneTreeTimer = get_tree().create_timer(HIT_PUSH_DUR)
			timer.timeout.connect(func(): _hit_dir = Vector2.ZERO)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_animation_finished(anim_name : StringName) -> void:
	match anim_name:
		&"appear":
			_appeared = true
			var timer : SceneTreeTimer = get_tree().create_timer(WAKEUP_TIME)
			timer.timeout.connect(func():
				if not _spawned and _anim.current_animation != &"spawn":
					_anim.play(&"spawn")
			)
		&"spawn":
			_spawned = true
		&"attack":
			if _target_attackable:
				_anim.play(&"attack")
			else:
				_anim.play(&"idle")

func _on_AttackArea_body_entered(body : Node2D) -> void:
	if body.is_in_group(TARGET_GROUP) and body == _target.get_ref():
		_target_attackable = true

func _on_AttackArea_body_exited(body : Node2D) -> void:
	if body == _target.get_ref() or _target.get_ref() == null:
		_target_attackable = false

func _on_wake_area_body_entered(body):
	if body.is_in_group(TARGET_GROUP):
		if not _appeared:
			_wake_body_seen = true
		elif not _spawned:
			if _anim.current_animation != &"spawn":
				_anim.play(&"spawn")

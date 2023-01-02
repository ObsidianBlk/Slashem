@tool
extends CharacterBody2D


# ------------------------------------------------------------------------------
# signals
# ------------------------------------------------------------------------------
signal hp_changed(hp, max_hp)
signal shake_requested(dur, amp, freq, pri)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SPEED : float = 100.0
const SWORD_ARC : float = deg_to_rad(90.0)
const MAX_HP : float = 100.0

# ------------------------------------------------------------------------------
# Exports
# ------------------------------------------------------------------------------
@export var sword_color : Color = Color.SKY_BLUE :	set = set_sword_color
@export var skin_color : Color = Color.WHEAT :		set = set_skin_color
@export var body_color : Color = Color.ORANGE :		set = set_body_color
@export var pant_color : Color = Color.CADET_BLUE :	set = set_pant_color
@export var short_sleeves : bool = false :			set = set_short_sleeve

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _dir : Vector2 = Vector2.ZERO
var _bodies : Array = []
var _attacking : bool = false
var _swish_audio : bool = false
var _hp : float = MAX_HP

var _drag_time : SceneTreeTimer = null
var _drag_mult : float = 1.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _weapon : Sprite2D = $Swivel/Weapon
@onready var _swivel : Node2D = $Swivel
@onready var _character : Node2D = $Character
@onready var _anim : AnimationPlayer = $Character/Anim

@onready var _head : Sprite2D = $Character/Upper/Head
@onready var _body : Sprite2D = $Character/Upper/Body
@onready var _arm_l : Sprite2D = $Character/Upper/ArmL
@onready var _arm_r : Sprite2D = $Character/Upper/ArmR
@onready var _leg_l : Sprite2D = $Character/LegL
@onready var _leg_r : Sprite2D = $Character/LegR

@onready var _sfx : Node2D = $SFX

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_sword_color(c : Color) -> void:
	if sword_color != c:
		sword_color = c
		_UpdateCharacterMaterials()

func set_skin_color(c : Color) -> void:
	if skin_color != c:
		skin_color = c
		_UpdateCharacterMaterials()

func set_body_color(c : Color) -> void:
	if body_color != c:
		body_color = c
		_UpdateCharacterMaterials()

func set_pant_color(c : Color) -> void:
	if pant_color != c:
		pant_color = c
		_UpdateCharacterMaterials()

func set_short_sleeve(s : bool) -> void:
	if short_sleeves != s:
		short_sleeves = s
		_UpdateCharacterMaterials()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateCharacterMaterials()
	if not Engine.is_editor_hint():
		hp_changed.emit(_hp, MAX_HP)

func _unhandled_input(event : InputEvent) -> void:
	if _hp <= 0.0 or Engine.is_editor_hint():
		_dir = Vector2.ZERO
	
	if event.is_action("up") or event.is_action("down"):
		_dir.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	elif event.is_action("left") or event.is_action("right"):
		_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	elif event.is_action_pressed("attack") and not event.is_echo():
		_SwingSword()


func _physics_process(_delta : float) -> void:
	if Engine.is_editor_hint():
		return
	
	if _dir.x != 0.0 or _dir.y != 0.0:
		_PlayAnim("run")
		if not _attacking:
			if _dir.x != 0.0:
				_Flip(_dir.x < 0.0)
	else:
		_PlayAnim("idle")
	velocity = _dir * SPEED * (0.5 if _attacking else 1.0) * _drag_mult
	move_and_slide()


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _SetShaderColor(s : Sprite2D, color : Color) -> void:
	var mat : ShaderMaterial = s.get_material()
	if mat != null:
		mat.set_shader_parameter("color", color)

func _UpdateCharacterMaterials() -> void:
	if _weapon != null:
		_SetShaderColor(_weapon, sword_color)
	if _head != null:
		_SetShaderColor(_head, skin_color)
	if _body != null:
		_SetShaderColor(_body, body_color)
	if _arm_l != null:
		_SetShaderColor(_arm_l, skin_color if short_sleeves else body_color)
	if _arm_r != null:
		_SetShaderColor(_arm_r, skin_color if short_sleeves else body_color)
	if _leg_l != null:
		_SetShaderColor(_leg_l, pant_color)
	if _leg_r != null:
		_SetShaderColor(_leg_r, pant_color)


func _SwingSword() -> void:
	if _attacking:
		return
	
	_attacking = true
	var tween : Tween = create_tween()
	_swish_audio = false
	tween.tween_method(_on_sword_attack, 0.0, SWORD_ARC, 0.1)
	tween.tween_method(_on_sword_return, SWORD_ARC, 0.0, 0.25)
	await tween.finished
	_attacking = false
	#tween.finished.connect(func(): _swinging = false)

func _Flip(e : bool = true) -> void:
	var nscale : float = -1.0 if e else 1.0
	if _swivel.scale.x != nscale:
		_swivel.scale.x = nscale
		_character.scale.x = nscale
		_bodies.clear()

func _Impact() -> void:
	if not _sfx.is_stream_playing(&"impact"):
		_sfx.play(&"impact", true, 1)
		shake_requested.emit(0.5, 3.0, 16.0, 0)

func _PlayAnim(anim_name : StringName) -> void:
	if _anim.current_animation != anim_name:
		_anim.play(anim_name)

func _PlayAudio(audio_name : StringName, is_group : bool = false) -> void:
	if is_group:
		_sfx.play_group(audio_name)
	else:
		_sfx.play(audio_name)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func hurt(amount : float, drag : float = 0.0, dur : float = 0.0) -> void:
	if Engine.is_editor_hint():
		return
	
	drag = max(0.0, min(1.0, drag))
	
	_hp = max(0.0, min(MAX_HP, _hp - amount))
	hp_changed.emit(_hp, MAX_HP)
	if _hp <= 0.0:
		if not _sfx.is_stream_playing(&"death"):
			_sfx.play(&"death", true, 0)
			Statistics.player_died()
	elif drag > 0.0 and dur > 0.0:
		_drag_mult = 1.0 - drag
		if _drag_time != null:
			_drag_time.timeout.disconnect(_on_drag_timeout)
		_drag_time = get_tree().create_timer(dur)
		_drag_time.timeout.connect(_on_drag_timeout)

func revive() -> void:
	if Engine.is_editor_hint():
		return
	_hp = MAX_HP
	hp_changed.emit(_hp, MAX_HP)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_sword_attack(v : float) -> void:
	if _bodies.size() > 0:
		for body in _bodies:
			if body.can_kill():
				body.kill()
				if _swish_audio == false:
					_Impact()
					_swish_audio = true
		#_bodies.clear()
	if _swish_audio == false:
		_sfx.play_group(&"swish", true, 2)
		_swish_audio = true
	_weapon.rotation = v

func _on_sword_return(v : float) -> void:
	_weapon.rotation = v

func _on_drag_timeout() -> void:
	_drag_mult = 1.0
	_drag_time = null

func _on_hit_zone_body_entered(body : Node2D) -> void:
	if Engine.is_editor_hint():
		return
	
	if body.has_method("kill"):
		if _attacking and body.can_kill():
			_Impact()
			body.kill()
		if _bodies.find(body) < 0:
			_bodies.append(body)

func _on_hit_zone_body_exited(body : Node2D) -> void:
	if Engine.is_editor_hint():
		return
	
	var idx : int = _bodies.find(body)
	if idx >= 0:
		_bodies.remove_at(idx)

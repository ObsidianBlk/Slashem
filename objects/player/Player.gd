extends CharacterBody2D


# ------------------------------------------------------------------------------
# signals
# ------------------------------------------------------------------------------
signal hp_changed(hp, max_hp)
signal killed()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SPEED : float = 100.0
const SWORD_ARC : float = deg_to_rad(90.0)
const MAX_HP : float = 100.0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _dir : Vector2 = Vector2.ZERO
var _bodies : Array = []
var _attacking : bool = false
var _hp : float = MAX_HP

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _weapon : Sprite2D = $Swivel/Weapon
@onready var _swivel : Node2D = $Swivel
@onready var _character : Node2D = $Character
@onready var _anim : AnimationPlayer = $Character/Anim

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	hp_changed.emit(_hp, MAX_HP)

func _unhandled_input(event : InputEvent) -> void:
	if _hp <= 0.0:
		return
	
	if event.is_action("up") or event.is_action("down"):
		_dir.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	elif event.is_action("left") or event.is_action("right"):
		_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	elif event.is_action_pressed("attack") and not event.is_echo():
		_SwingSword()


func _physics_process(_delta : float) -> void:
	if _dir.x != 0.0 or _dir.y != 0.0:
		_PlayAnim("run")
		if _dir.x != 0.0:
			_Flip(_dir.x < 0.0)
	else:
		_PlayAnim("idle")
	velocity = _dir * SPEED
	move_and_slide()


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _SwingSword() -> void:
	if _attacking:
		return
	
	_attacking = true
	var tween : Tween = create_tween()
	tween.tween_method(_on_sword_attack, 0.0, SWORD_ARC, 0.1)
	tween.tween_method(_on_sword_return, SWORD_ARC, 0.0, 0.25)
	await tween.finished
	_attacking = false
	#tween.finished.connect(func(): _swinging = false)

func _Flip(e : bool = true) -> void:
	_swivel.scale.x = -1.0 if e else 1.0
	_character.scale.x = -1.0 if e else 1.0
	_bodies.clear()

func _PlayAnim(anim_name : StringName) -> void:
	if _anim.current_animation != anim_name:
		_anim.play(anim_name)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func hurt(amount : float) -> void:
	_hp = max(0.0, min(MAX_HP, _hp - amount))
	hp_changed.emit(_hp, MAX_HP)
	if _hp <= 0.0:
		killed.emit()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_sword_attack(v : float) -> void:
	if _bodies.size() > 0:
		for body in _bodies:
			body.kill()
		_bodies.clear()
	_weapon.rotation = v

func _on_sword_return(v : float) -> void:
	_weapon.rotation = v

func _on_hit_zone_body_entered(body : Node2D) -> void:
	if body.has_method("kill"):
		if _attacking:
			body.kill()
		elif _bodies.find(body) < 0:
			_bodies.append(body)

func _on_hit_zone_body_exited(body : Node2D) -> void:
	var idx : int = _bodies.find(body)
	if idx >= 0:
		_bodies.remove_at(idx)

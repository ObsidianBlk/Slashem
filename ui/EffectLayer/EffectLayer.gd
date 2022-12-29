extends CanvasLayer

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var transition_color : Color = Color.SLATE_GRAY :	set = set_transition_color

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _transition : ColorRect = $Transition

# ------------------------------------------------------------------------------
# Setter
# ------------------------------------------------------------------------------
func set_transition_color(c : Color) -> void:
	transition_color = c
	if _transition != null:
		_transition.color = transition_color

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_transition_color(transition_color)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func fade_in(transition_time : float, callback = null) -> void:
	var mat : ShaderMaterial = _transition.get_material()
	if mat != null:
		mat.set_shader_parameter("progress", 1.0)
		var tween : Tween = create_tween()
		tween.tween_property(mat, "shader_param/progress", 0.0, transition_time)
		await tween.finished
		if callback is Callable:
			callback.call()


func fade_out(transition_time : float, callback = null) -> void:
	var mat : ShaderMaterial = _transition.get_material()
	if mat != null:
		mat.set_shader_parameter("progress", 0.0)
		var tween : Tween = create_tween()
		tween.tween_property(mat, "shader_param/progress", 1.0, transition_time)
		await tween.finished
		if callback is Callable:
			callback.call()



extends CanvasLayer


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _transition : ColorRect = $Transition

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func fade_in(transition_time : float, callback : Callable = null) -> void:
	var mat : ShaderMaterial = _transition.get_material()
	if mat != null:
		mat.set_shader_parameter("progress", 1.0)
		var tween : Tween = create_tween()
		tween.tween_property(mat, "shader_param/progress", 0.0, transition_time)
		await tween.finished
		if callback != null:
			callback.call()


func fade_out(transition_time : float, callback : Callable = null) -> void:
	var mat : ShaderMaterial = _transition.get_material()
	if mat != null:
		mat.set_shader_parameter("progress", 0.0)
		var tween : Tween = create_tween()
		tween.tween_property(mat, "shader_param/progress", 1.0, transition_time)
		await tween.finished
		if callback != null:
			callback.call()



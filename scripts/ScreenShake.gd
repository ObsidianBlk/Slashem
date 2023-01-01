extends Node
class_name ScreenShake


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal finished()

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _priority : int = 0
var _dur_timer : SceneTreeTimer = null
var _tween : Tween = null
var _camera : Camera2D = null

var _active_freq_time : float = 0.0
var _active_amplitude : float = 0.0


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	var parent = get_parent()
	if parent is Camera2D:
		_camera = parent
	else:
		printerr("ScreenShake node not attached to a Camera2D!")

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _new_shake() -> void:
	var rand : Vector2 = Vector2(
		randf_range(-_active_amplitude, _active_amplitude),
		randf_range(-_active_amplitude, _active_amplitude)
	)
	_StopTween()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_camera, "offset", rand, _active_freq_time)
	_tween.finished.connect(_on_tween_finished)

func _StopTween() -> void:
	if _tween != null:
		_tween.stop()
		_tween.kill()
		_tween = null

func _ClearDurationTimer() -> void:
	if _dur_timer != null:
		_dur_timer.timeout.disconnect(_on_duration_timeout)
		_dur_timer = null

func _Reset() -> void:
	_StopTween()
	_tween = create_tween()
	_tween.tween_property(_camera, "offset", Vector2.ZERO, _active_freq_time)
	_tween.finished.emit(func():
		_priority = 0 
		finished.emit()
	)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func shake(duration : float, amplitude : float, frequency : float, priority : int = 0) -> void:
	if _camera != null and (_dur_timer == null or _priority < priority):
		if _dur_timer != null:
			stop()
		_active_amplitude = amplitude
		_active_freq_time = 1 / frequency
		_dur_timer = get_tree().create_timer(duration)
		_dur_timer.timeout.connect(_on_duration_timeout)
		_new_shake()

func stop(in_place : bool = false) -> void:
	if _dur_timer != null:
		_ClearDurationTimer()
		_StopTween()
		if not in_place and _camera != null:
			_camera.offset = Vector2.ZERO

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_duration_timeout() -> void:
	_ClearDurationTimer()
	_Reset()

func _on_tween_finished() -> void:
	_StopTween()
	if _dur_timer != null:
		_new_shake()
	


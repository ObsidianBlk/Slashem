extends Control


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _time_label : Label = $Layout/Control/Time
@onready var _progress : ProgressBar = $Layout/Control/ProgressBar

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Statistics.run_time_changed.connect(_on_time_changed)


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _TimeToString(t : float) -> String:
	var min : float = t / 60.0
	var sec : float = fmod(t, 60.0)
	return "%02d:%02d"%[min, sec]

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_time_changed(remaining : float, total : float) -> void:
	var val : float = 0.0
	if total > 0.0:
		val = (remaining / total) * 100.0
	_progress.value = val
	_time_label.text = _TimeToString(remaining)

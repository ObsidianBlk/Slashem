extends Node2D

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal music_ended()

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _music : AudioStreamPlayer = null
var _start_duration : float = -1.0

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_music = get_node_or_null("Music")
	if _start_duration >= 0.0:
		start_music(_start_duration)
		_start_duration = -1.0


# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_player_start() -> Vector2:
	for child in get_children():
		if child.name == &"PlayerStart" and child is Node2D:
			return child.global_position
	return Vector2.ZERO

func clear_moblings() -> void:
	for child in get_children():
		if child.is_in_group(&"mobling"):
			child.queue_free()

func start_music(duration : float) -> void:
	if _music != null:
		_music.play()
		var max_db : float = db_to_linear(_music.volume_db)
		_music.volume_db = linear_to_db(0.0)
		var updater : Callable = func(v): _music.volume_db = linear_to_db(v)
		var tween : Tween = create_tween()
		tween.tween_method(updater, 0.0, max_db, duration)
	else:
		_start_duration = duration

func end_music(duration : float) -> void:
	if _music != null:
		var updater : Callable = func(v): _music.volume_db = linear_to_db(v)
		var tween : Tween = create_tween()
		tween.tween_method(updater, db_to_linear(_music.volume_db), 0.0, duration)
		tween.finished.connect(func() : music_ended.emit())

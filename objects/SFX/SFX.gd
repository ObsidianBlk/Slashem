extends Node2D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal finished()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var sample_names : Array[StringName] = []
@export var sample_streams : Array[AudioStream] = []
@export var sample_groups : Array[String] = []

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _groups : Dictionary = {}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _audio1 : AudioStreamPlayer2D = $Audio1
@onready var _audio2 : AudioStreamPlayer2D = $Audio2

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_sample_groups(sg : Array[String]) -> void:
	sample_groups = sg
	var group_names : Array = []
	for group in sample_groups:
		var group_name : StringName = _AddSampleGroup(group)
		if group_name != &"":
			group_names.append(group_name)
	_ClearMissingSampleGroups(group_names)


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_sample_groups(sample_groups)
	_audio1.finished.connect(_on_audio_finished.bind(_audio1))
	_audio2.finished.connect(_on_audio_finished.bind(_audio2))


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ClearMissingSampleGroups(groups : Array) -> void:
	var keys : Array = _groups.keys()
	for key in keys:
		if groups.find(key) < 0:
			_groups.erase(key)


func _AddSampleGroup(group_def : String) -> StringName:
	var ginfo : Array = group_def.split(",")
	for i in range(ginfo.size()):
		ginfo[i] = ginfo[i].strip_edges()
	var group_name : StringName = &""
	if ginfo.size() > 2 and ginfo[0] != "":
		group_name = StringName(ginfo[0])
		_groups[group_name] = ginfo.slice(1, ginfo.size())
	return group_name

func _GetAvailableStream() -> AudioStreamPlayer2D:
	for stream in [_audio1, _audio2]:
		if not stream.playing:
			return stream
	return null

func _GetStreamName(audio : AudioStreamPlayer2D) -> StringName:
	if audio.stream != null:
		var idx : int = sample_streams.find(audio.stream)
		if idx >= 0:
			return sample_names[idx]
	return &""

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func stop() -> void:
	_audio1.stop()
	_audio1.stream = null
	_audio2.stop()
	_audio2.stream = null

func play(stream_name : StringName, force : bool = false, id : int = 0) -> void:
	var idx : int = sample_names.find(stream_name)
	if not (idx >= 0 and idx < sample_streams.size()):
		return
	var audio : AudioStreamPlayer2D = _GetAvailableStream()
	if audio == null and force:
		audio = _audio1 if id == 0 else _audio2
	if audio != null:
		audio.stop()
		audio.stream = sample_streams[idx]
		audio.play()

func is_stream_playing(stream_name : StringName) -> bool:
	for audio in [_audio1, _audio2]:
		if audio.playing and stream_name == _GetStreamName(audio):
			return true
	return false

func play_group(group_name : StringName, force : bool = false, id : int = 0) -> void:
	if group_name in _groups:
		var idx : int = randi_range(0, _groups[group_name].size() - 1)
		play(_groups[group_name][idx], force, id)

func is_group_playing(group_name : StringName) -> bool:
	for audio in [_audio1, _audio2]:
		var stream_name : StringName = _GetStreamName(audio)
		if stream_name in _groups:
			return true
	return false

func get_playing_streams() -> PackedStringArray:
	var streams : Array = []
	for audio in [_audio1, _audio2]:
		var sname : StringName = _GetStreamName(audio)
		if sname != &"":
			streams.append(sname)
	return PackedStringArray(streams)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_audio_finished(audio : AudioStreamPlayer2D) -> void:
	finished.emit()

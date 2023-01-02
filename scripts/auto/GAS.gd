extends Node


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal audio_bus_volume_changed(bus_name, linear_volume)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SECTION : String = "Settings"

enum AUDIO_BUS {Master=0, Music=1, SFX=2}
const AUDIO_BUS_NAMES : Array = [
	"Master",
	"Music",
	"SFX"
]

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func load_from_config(conf : ConfigFile) -> void:
	for i in range(AUDIO_BUS_NAMES.size()):
		var key : String = "Volume.%s"%[AUDIO_BUS_NAMES[i]]
		if conf.has_section_key(SECTION, key):
			var val = conf.get_value(SECTION, key)
			if typeof(val) == TYPE_FLOAT:
				set_audio_volume(i, val)

func save_to_config(conf : ConfigFile) -> void:
	for i in range(AUDIO_BUS_NAMES.size()):
		var key : String = "Volume.%s"%[AUDIO_BUS_NAMES[i]]
		conf.set_value(SECTION, key, get_audio_volume(i))

func set_audio_volume(bus_id : int, vol : float) -> void:
	var bus_idx : int = -1
	if bus_id >= 0 and bus_id < AUDIO_BUS_NAMES.size():
		bus_idx = AudioServer.get_bus_index(AUDIO_BUS_NAMES[bus_id])
	
	if bus_idx >= 0:
		vol = max(0.0, min(1.0, vol))
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(vol))
		audio_bus_volume_changed.emit(AUDIO_BUS_NAMES[bus_id], vol)

func get_audio_volume(bus_id : int) -> float:
	var bus_idx : int = -1
	if bus_id >= 0 and bus_id < AUDIO_BUS_NAMES.size():
		bus_idx = AudioServer.get_bus_index(AUDIO_BUS_NAMES[bus_id])
	
	if bus_idx >= 0:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return -1.0

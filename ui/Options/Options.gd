extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal menu_change_requested(menu_name)
signal request_sent(info)


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var return_menu_name : StringName = ""

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _master_slider : HSlider = $Layout/Master/HSlider
@onready var _music_slider : HSlider = $Layout/Music/HSlider
@onready var _sfx_slider : HSlider = $Layout/SFX/HSlider

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	GAS.audio_bus_volume_changed.connect(_on_audio_bus_volume_changed)
	_master_slider.value = GAS.get_audio_volume(GAS.AUDIO_BUS.Master) * 100.0
	_music_slider.value = GAS.get_audio_volume(GAS.AUDIO_BUS.Music) * 100.0
	_sfx_slider.value = GAS.get_audio_volume(GAS.AUDIO_BUS.SFX) * 100.0

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_if_named(ui_name : StringName) -> void:
	visible = ui_name == name
	if visible:
		_master_slider.grab_focus()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_audio_bus_volume_changed(bus_name : String, linear_volume : float) -> void:
	match bus_name:
		"Master":
			_master_slider.value = linear_volume * 100.0
		"Music":
			_music_slider.value = linear_volume * 100.0
		"SFX":
			_sfx_slider.value = linear_volume * 100.0


func _on_master_value_changed(value : float) -> void:
	GAS.set_audio_volume(GAS.AUDIO_BUS.Master, value / 100.0)

func _on_music_value_changed(value : float) -> void:
	GAS.set_audio_volume(GAS.AUDIO_BUS.Music, value / 100.0)

func _on_sfx_value_changed(value : float) -> void:
	GAS.set_audio_volume(GAS.AUDIO_BUS.SFX, value / 100.0)

func _on_apply_pressed():
	request_sent.emit({&"request": &"apply_audio_config"})
	menu_change_requested.emit(return_menu_name)

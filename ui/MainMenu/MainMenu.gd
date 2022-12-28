extends Control


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal game_start_requested()
signal options_requested()
signal stats_requested()
signal quit_requested()

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _pointer : Control = $WeaponPointer
@onready var _item_start : Button = $Main/Menu/Start
@onready var _item_options : Button = $Main/Menu/Options
@onready var _item_stats : Button = $Main/Menu/Stats
@onready var _item_quit : Button = $Main/Menu/Quit

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_item_start.focus_entered.connect(_on_button_focused.bind(_item_start))
	_item_start.mouse_entered.connect(_on_button_focused.bind(_item_start))
	
	_item_options.focus_entered.connect(_on_button_focused.bind(_item_options))
	_item_options.mouse_entered.connect(_on_button_focused.bind(_item_options))
	
	_item_stats.focus_entered.connect(_on_button_focused.bind(_item_stats))
	_item_stats.mouse_entered.connect(_on_button_focused.bind(_item_stats))
	
	_item_quit.focus_entered.connect(_on_button_focused.bind(_item_quit))
	_item_quit.mouse_entered.connect(_on_button_focused.bind(_item_quit))


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func show_if_named(ui_name : StringName) -> void:
	visible = ui_name == name
	if visible:
		_on_button_focused(_item_start)
		_item_start.grab_focus()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_button_focused(btn : Button) -> void:
	var targ : Vector2 = btn.global_position + (Vector2.DOWN * (btn.size.y * 0.5))
	_pointer.rotation = _pointer.global_position.angle_to_point(targ)

func _on_start_pressed():
	game_start_requested.emit()

func _on_options_pressed():
	options_requested.emit()

func _on_stats_pressed():
	stats_requested.emit()

func _on_quit_pressed():
	quit_requested.emit()

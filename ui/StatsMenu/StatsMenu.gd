extends MarginContainer


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal menu_change_requested(menu_name)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const MAIN_TITLE : StringName = &"main"
const VICTORY_TITLE : StringName = &"victory"
const DIED_TITLE : StringName = &"died"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var back_menu_name : StringName = &""
@export var main_title : String = "Statistics"
@export var main_color : Color = Color.KHAKI
@export var victory_title : String = "VICTORY Over the Dungeon"
@export var victory_color : Color = Color.LIGHT_GOLDENROD
@export var died_title : String = "The MOBS Claim the Dungeon"
@export var died_color : Color = Color.TOMATO

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _maintitle : Label = $Layout/MainTitle
@onready var _back_button : Button = $Layout/Options/Back

@onready var _runs_value : Label = $Layout/Info/LooseInfo/Runs/Value
@onready var _abandoned_value : Label = $Layout/Info/LooseInfo/Abandoned/Value
@onready var _deaths_value : Label = $Layout/Info/LooseInfo/Deaths/Value
@onready var _kills_value : Label = $Layout/Info/LooseInfo/Kills/Value
@onready var _kdr_value : Label = $Layout/Info/LooseInfo/KDR/Value

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Statistics.stats_loaded.connect(_UpdateStats)
	Statistics.run_completed.connect(_on_run_completed)
	_UpdateTitle(MAIN_TITLE)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateTitle(title : StringName) -> void:
	match title:
		MAIN_TITLE:
			_maintitle.text = main_title
			_maintitle.add_theme_color_override("font_color", main_color)
		VICTORY_TITLE:
			_maintitle.text = victory_title
			_maintitle.add_theme_color_override("font_color", victory_color)
		DIED_TITLE:
			_maintitle.text = died_title
			_maintitle.add_theme_color_override("font_color", died_color)

func _UpdateStats(info : Dictionary) -> void:
	_runs_value.text = "%s"%[info.runs]
	_abandoned_value.text = "%s"%[info.abandoned]
	_deaths_value.text = "%s"%[info.deaths]
	_kills_value.text = "%s"%[info.kills]
	if info.deaths <= 0:
		_kdr_value.text = "INF"
	else:
		_kdr_value.text = "%02d"%[float(info.kills) / float(info.deaths)]

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func show_if_named(ui_name : StringName) -> void:
	visible = ui_name == name
	if not visible:
		_UpdateTitle(MAIN_TITLE)
	else:
		_back_button.grab_focus()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_run_completed(player_died : bool) -> void:
	_UpdateTitle(DIED_TITLE if player_died else VICTORY_TITLE)
	_UpdateStats(Statistics.get_stats())

func _on_back_pressed():
	menu_change_requested.emit(back_menu_name)

func _on_reset_pressed():
	Statistics.reset_statistics()
